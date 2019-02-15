<?php
// change max time from 300s (5 min) to 1000s (17 min)
ini_set('MAX_EXECUTION_TIME', 1000);

error_log(date('Y-m-d h:i:s a', time()) . "    [analyze.php]: \n", 3, $_SERVER['DOCUMENT_ROOT']."/targettranslator/php.log");

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

        // find old name and define new name - clinical
        $demo_clinical_file = "../data/" . $demo_datasets[$i] . "_clinical.tsv";
        $new_demo_clinical_file = "../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv";

        // find old name and define new name - expression
        $demo_expression_file = "../data/" . $demo_datasets[$i] . "_expression.tsv";
        $new_demo_expression_file = "../data/job_" . $job_id . "/expression_$unique_ids[$unique_ids_index].tsv";

        // copy and rename the copied file - clinical
        if (!copy($demo_clinical_file, $new_demo_clinical_file)) {
            $validation_errors["no_copy_clinical_file"] = "Preprocess Error: The clinical data could not copied.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        // copy and rename the copied file - expression
        if (!copy($demo_expression_file, $new_demo_expression_file)) {
            $validation_errors["no_copy_expression_file"] = "Preprocess Error: The expression data could not copied.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        // Check if clinical file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_clinical_file"] = "Preprocess Error: The clinical data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        // Check if expression file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/expression_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_expression_file"] = "Preprocess Error: The expression data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        $unique_ids_index++;
    }
}


// Handle uploaded datasets
if (!empty($_FILES["files_clinical"]) && !empty($_FILES["files_expression"]) &&
    count($_FILES["files_clinical"]["name"]) == count($_FILES["files_expression"]["name"])) {

    $uploaded_clinical_datasets = $_FILES["files_clinical"]["name"];
    $uploaded_expression_datasets = $_FILES["files_expression"]["name"];
    $num_datasets += count($uploaded_clinical_datasets);

    for ($i = 0; $i < count($uploaded_clinical_datasets); $i++) {

        // generate unique identifier
        $unique_ids[$unique_ids_index] = uniqid();

        // clinical file
        $info = pathinfo($uploaded_clinical_datasets[$i]);
        $extension = $info["extension"]; // get the extension of the file
        $new_name_clinical = "clinical_$unique_ids[$unique_ids_index].tsv";
        $target = "../data/job_" . $job_id . "/" . $new_name_clinical;
        move_uploaded_file( $_FILES["files_clinical"]["tmp_name"][$i], $target);

        // expression file
        $info = pathinfo($uploaded_expression_datasets[$i]);
        $extension = $info["extension"]; // get the extension of the file
        $new_name_expression = "expression_$unique_ids[$unique_ids_index].tsv";
        $target = "../data/job_" . $job_id . "/" . $new_name_expression;
        move_uploaded_file( $_FILES["files_expression"]["tmp_name"][$i], $target);

        // Check if clinical file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/clinical_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_clinical_file"] = "Preprocess Error: The clinical data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        // Check if expression file exists and is readable
        if (!is_readable("../data/job_" . $job_id . "/expression_$unique_ids[$unique_ids_index].tsv")) {
            $validation_errors["no_expression_file"] = "Preprocess Error: The expression data could not be read.";
            echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
            removeData($job_id);
            return;
        }

        $unique_ids_index++;
    }
} else if (empty($_FILES["files_clinical"]) && empty($_FILES["files_expression"])) {
    // do nothing, this is ok
} else {
    // if the number of clinical and expression datasets differ, return error
    $validation_errors["diff_file_counts"] = "Preprocess Error: Please upload both clinical and expression data for each patient group.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}

// if no dataset has been uploaded, return error
if (count($unique_ids) == 0) {
    $validation_errors["no_datasets"] = "Preprocess Error: Please select or uploaded at least one dataset.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}


// ================================================================= validate settings ===

// Check if checkbox values has been sent
if (is_null($_POST['log_check']) || is_null($_POST['run_cox'])) {
    $validation_errors["no_settings"] = "The settings were not transferred to the server.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}

// Check if cox variables has been specified when running the cox analysis
if ($_POST['run_cox'] === TRUE && (empty($_POST['survival']) || empty($_POST['is_alive']))) {
    $validation_errors["no_cox"] = "Please specifiy what variables to use in the Cox proportional hazards model.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}


// ================================================== create/save stratifications file ===

// use the first unique id created in the loop, at least one must have been created to get this far...
$stratifications = json_decode($_POST['stratifications']);

// open the file "stratifications.tsv" for writing
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
    $validation_errors["no_stratification_file"] = "The stratification data could not be read.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}


// ===================================================== create/save gene markers file ===

$markers_negative = json_decode($_POST['markers_negative']);
$markers_positive = json_decode($_POST['markers_positive']);

$markers_negative_weights = array();
$markers_positive_weights = array();

foreach ($markers_negative as $row) {
    $markers_negative_weights[] = array($row, -1);
}
foreach ($markers_positive as $row) {
    $markers_positive_weights[] = array($row, 1);
}

// open the file "markers.tsv" for writing
$file = fopen("../data/job_" . $job_id . "/markers_$unique_ids[0].tsv", "w");

// add column headers
fputcsv($file, array("gene", "direction"), chr(9));

// save each row of the data
foreach ($markers_negative_weights as $row) {
    fputcsv($file, $row, chr(9));
}
foreach ($markers_positive_weights as $row) {
    fputcsv($file, $row, chr(9));
}

// Close the file
fclose($file);

// Check if stratification file exists and is readable
if (!is_readable("../data/job_" . $job_id . "/markers_$unique_ids[0].tsv")) {
    $validation_errors["no_markers_file"] = "The markers genes could not be read.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}

// ========================================================= create/save settings file ===

$log_check  = $_POST['log_check'];
$run_cox    = $_POST['run_cox'];
$L1000_type = $_POST['L1000_type'];
$survival   = $_POST['survival'];
$is_alive   = $_POST['is_alive'];

// open the file "stratifications.tsv" for writing
$file = fopen("../data/job_" . $job_id . "/settings_$unique_ids[0].tsv", "w");

// save the column headers
fputcsv($file, array('setting', 'value'), chr(9));

// create data
$file_data = array(
    array("log2_transformed", $log_check),
    array("run_cox", $run_cox),
    array("L1000_type", $L1000_type),
    array("survival", $survival),
    array("is_alive", $is_alive)
);

// save each row of the data
// The ascii code for tab is 9, so chr(9) returns a tab character
foreach ($file_data as $row) {
    fputcsv($file, $row, chr(9));
}

// Close the file
fclose($file);

// Check if settings file exists and is readable
if (!is_readable("../data/job_" . $job_id . "/settings_$unique_ids[0].tsv")) {
    $validation_errors["no_settings_file"] = "The settings could not be read.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    removeData($job_id);
    return;
}


// ================================================================== Call Rscript.exe ===

// check amount of available RAM on server, if more than 600 MB, run R-script
// note works only on linux server
/*exec("free -mtl", $memory);
$free_memory = preg_split('/\s+/', $memory[1]);

if ((int)$free_memory[3] < 600) {
    $validation_errors["no_memory"] = "We are working on other stuff. Try again in a minute or two.";
    echoResult(FALSE, $validation_errors, NULL, NULL, NULL);
    return;
}*/


/*$command =
    'C:\"Program Files"\R\R-3.4.3\bin\Rscript.exe ' .
    'C:\xampp\htdocs\targettranslator\r_scripts\discover.R ' .
    'C:\xampp\htdocs\targettranslator\data\expression.tsv ' .
    'C:\xampp\htdocs\targettranslator\data\clinical.tsv ' .
    'C:\xampp\htdocs\targettranslator\data\stratifications.tsv ' .
    'C:\xampp\htdocs\targettranslator\data\settings.tsv ';*/


// define command to be sent to the terminal
// note! Rscript.exe must be defined in the path on the server, otherwise, specify absolute path

// create string of expression files
$expression_command = "\"c(";
$clinical_command = "\"c(";

for ($i = 0; $i < $num_datasets; $i++) {
    $expression_command .= "'../data/job_" . $job_id . "/expression_$unique_ids[$i].tsv',";
}

// create string of clinical files
for ($i = 0; $i < $num_datasets; $i++) {
    $clinical_command .= "'../data/job_" . $job_id . "/clinical_$unique_ids[$i].tsv',";
}

$expression_command = rtrim($expression_command,", ");
$clinical_command = rtrim($clinical_command,", ");
$expression_command .= ")\" ";
$clinical_command .= ")\" ";

// merge all subcommands to one
$command =
    "Rscript " .
    "\"../r_scripts/discover.R\" " .
    "\"../data/job_" . $job_id . "/stratifications_$unique_ids[0].tsv\" " .
    "\"../data/job_" . $job_id . "/settings_$unique_ids[0].tsv\" " .
    $expression_command .
    $clinical_command .
    "\"" . $job_id . "\" " .
    "\"../data/job_" . $job_id . "/markers_$unique_ids[0].tsv\" ";

error_log(date('Y-m-d h:i:s a', time()) . "    [analyze.php]: $command \n", 3, $_SERVER['DOCUMENT_ROOT']."/targettranslator/php.log");
// execute command
// output in the terminal is stored in $output
// $status contain possible error codes, 0 if none

exec($command, $output, $status);

// ================================================================= return a response ===

// Check if there are errors from the R-script, else return the results
$data = json_decode($output[0], true);

// output[0] contains error or, if successful, the result table
// output[1] contains enrichment table
// output[2] contains information about the analysis

if ($data[0] == "error") {
    echoResult(FALSE, NULL, $data, NULL, NULL);
} else {
    echoResult(TRUE, NULL, NULL, NULL, array($data, json_decode($output[1], true)));
}

// remove job folder
removeData($job_id);

error_log(date('Y-m-d h:i:s a', time()) . "    [analyze.php]: \n", 3, $_SERVER['DOCUMENT_ROOT']."/targettranslator/php.log");

return;
