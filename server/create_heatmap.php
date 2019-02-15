<?php
// TODO: add error messages

ini_set('memory_limit', '-1');


/**
 * Assemble result into an associative array and echo it
 * @param $success
 * @param $validation_errors
 * @param $analysis_errors
 * @param $info
 * @param $data
 */
function echoResult($success, $validation_errors, $analysis_errors, $info, $data) {
    $result['success']              = $success;
    $result['validation_errors']    = $validation_errors;
    $result['analysis_errors']      = $analysis_errors;
    $result['info']                 = $info;
    $result['data']                 = $data;

    echo json_encode($result);
}

function removeData($job_id) {
    $path = "../data/job_" . $job_id;

    if (file_exists($path)) {
        $dir = opendir($path);
        while (false !== ($file = readdir($dir))) {
            if (($file != '.') && ($file != '..')) {
                $full = $path . '/' . $file;
                if (is_dir($full)) {
                    removeData($full);
                } else {
                    unlink($full);
                }
            }
        }
        closedir($dir);
        rmdir($path);
    }
}

// create variables
$validation_errors  = array();  // array to hold validation errors
$analysis_errors    = array();  // array to hold analysis errors
$info               = array();  // array to hold analysis information
$unique_ids         = array();  // array to hold all unique ID for every file
$unique_ids_index   = 0;        // number to keep track of position when adding unique IDs
$num_datasets       = 0;        // number of datasets, both demo and user-supplied


// ========================================================================= job setup ===

// give job a unique identifier
$job_id = uniqid();

// create job folder
if (!mkdir("../data/job_" . $job_id)) {
    $validation_errors["no_folder"] = "Preprocess Error: Could not create job folder.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    return;
}


// =============================================================== validate user input ===

// Handle demo datasets
if(!empty($_POST['demo_datasets'])) {
    $demo_datasets = json_decode($_POST['demo_datasets']);
    $num_datasets += count($demo_datasets);

    for ($i = 0; $i < count($demo_datasets); $i++) {

        // generate unique identifier
        $unique_ids[$unique_ids_index] = uniqid();

        // find old name and define new name
        $demo_clinical_file = "../data/" . $demo_datasets[$i] . "_clinical.tsv";
        $new_demo_clinical_file = "../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv";

        // copy and rename the copied file
        if (!copy($demo_clinical_file, $new_demo_clinical_file)) {
            $validation_errors["no_copy_clinical_file"] = "Preprocess Error: The clinical data could not copied.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            return;
        }

        // Check if clinical file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_clinical_file"] = "Preprocess Error: The clinical data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            return;
        }

        $unique_ids_index++;
    }
}


// Handle uploaded datasets
if (!empty($_FILES["files_clinical"])) {
    $uploaded_datasets = $_FILES["files_clinical"]["name"];
    $num_datasets += count($uploaded_datasets);

    for ($i = 0; $i < count($uploaded_datasets); $i++) {

        // generate unique identifier
        $unique_ids[$unique_ids_index] = uniqid();

        // clinical file
        $info = pathinfo($uploaded_datasets[$i]);
        $extension = $info["extension"]; // get the extension of the file
        $new_name_clinical = "clinical_$unique_ids[$unique_ids_index].tsv";
        $target = "../data/job_" . $job_id . "/" . $new_name_clinical;
        move_uploaded_file( $_FILES["files_clinical"]["tmp_name"][$i], $target);

        // Check if clinical file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_clinical_file"] = "Preprocess Error: The clinical data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            return;
        }

        $unique_ids_index++;
    }
}


// ================================================== create/save stratifications file ===

// use the first unique id for the stratifications files
$stratifications = json_decode($_POST['stratifications']);

// open the file "stratifications.csv" for writing
$file = fopen("../data/job_" . $job_id . "/stratifications_$unique_ids[0].tsv", "w");

// save each row of the data
// The ascii code for tab is 9, so chr(9) returns a tab character
foreach ($stratifications as $row) {
    fputcsv($file, array($row), chr(9));
}

// Close the file
fclose($file);

// Check if stratification file exists and is readable
if (!is_readable("../data/job_" . $job_id . "/stratifications_$unique_ids[0].tsv")) {
    $validation_errors["no_stratification_file"] = "Preprocess Error: The stratification data could not be read.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    return;
}


// ================================================================== Call Rscript.exe ===

// check amount of available RAM on server, if more than 600 MB, run R-script
// note works only on linux server
/*exec("free -mtl", $memory);
$free_memory = preg_split('/\s+/', $memory[1]);

if ((int)$free_memory[3] < 600) {
    $validation_errors["no_memory"] = "We are working on other stuff. Try again in a minute or two. -server";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    return;
}*/


// define command to be sent to the terminal
// note! Rscript.exe must be defined in the path on the server, otherwise, specify absolute path

// create string of clinical files
$clinical_command = "\"c(";

// create string of clinical files
for ($i = 0; $i < $num_datasets; $i++) {
    $clinical_command .= "'../data/job_" . $job_id . "/clinical_$unique_ids[$i].tsv',";
}

$clinical_command = rtrim($clinical_command,", ");
$clinical_command .= ")\" ";

// merge all subcommands to one
$command =
    "Rscript " .
    "\"../r_scripts/createHeatmap.R\" " .
    "\"../data/job_" . $job_id . "/stratifications_$unique_ids[0].tsv\" " .
    $clinical_command .
    "\"" . $job_id . "\"";

// execute command
// output in the terminal is stored in $output
// $status contain possible error codes, 0 if none
exec($command, $output, $status);

error_log(date('Y-m-d h:i:s a', time()) . "    [analyze.php]: $command \n", 3, $_SERVER['DOCUMENT_ROOT']."/targettranslator/php.log");

// ================================================================= return a response ===

// Check if there are errors from the R-script, else return the results
$data = json_decode($output[0], true);
error_log(date('Y-m-d h:i:s a', time()) . "    [analyze.php]: " . print_r($output, true). " \n", 3, $_SERVER['DOCUMENT_ROOT']."/targettranslator/php.log");
if ($data[0] == "error") {
    echoResult(FALSE, NULL, $data, NULL, NULL);
} else {
    echoResult(TRUE, NULL, NULL, NULL, array($output[0], $output[1]));
}

// remove job folder
removeData($job_id);

return;
