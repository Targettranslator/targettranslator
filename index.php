<!DOCTYPE html>
<html lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0" />
    <title>Target Translator</title>

    <!-- favicon -->
     <link rel="shortcut icon" type="image/png" href="/_img/favicon.ico" />

    <!-- Open Sans -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:300,400,600" >

    <!-- CSS Reset Normalize -->
    <link rel="stylesheet" href="/_css/normalize.css" type="text/css"  media="screen,projection" />

    <!-- Bootstrap tour -->
    <link rel="stylesheet" href="/_plugins/bootstrap-tour/bootstrap-tour-standalone.min.css" type="text/css"  media="screen,projection" />

    <!-- CSS Custom -->
    <link rel="stylesheet" href="/_css/style.css" type="text/css"  media="screen,projection" />

</head>
<body>

<div id="app-container">

    <div id="landing" class="component">
        <div id="particles-js"></div>

        <div id="intro">

            <div id="secondary-menu">
                <!--<button onclick="showComponent('documentation')">Documentation</button>
                <button onclick="showComponent('contact')">Contact</button>-->
<!--                <button>Documentation</button>-->
<!--                <button>Contact</button>-->
            </div>

            <h1>TargetTranslator <sup> BETA</sup> </h1>

            <p>
                You have reached the TargetTranslator, an interactive tool that enables the creation
                of gene signatures and exploration of their connections to different compounds.
            </p>
            <p>
                TargetTranslator is currently in beta and new functionality will be added continuously.
            </p>

            <div id="start-actions">
                <button id="analysis-button" class="ghost" onclick="showComponent('analysis')">ANALYSE MY DATA</button>
<!--                <button onclick="showComponent('rpackage')">DOWNLOAD <br> SOURCE CODE <br> (comming soon)</button>-->
<!--                <button>DOWNLOAD <br> SOURCE CODE <br> (comming soon)</button>-->
            </div>


        </div>

    </div>


    <div id="analysis" class="component ">

        <div class="top-stripe"></div>

        <div class="back-button" onclick="showComponent('landing')">
            <i class="back-arrow"></i>
            <span>Back</span>
        </div>

        <div id="start-tour">
            <!-- start tour -->
        </div>

        <div class="center-container">

            <h1 id="start-title">Insights are waiting, let's get started.</h1>

            <h2>1. Select Data</h2>
            <div class="instructions">
                <p>Upload your own dataset and/or add data from the preprocessed ones.</p>
                <p>If you upload your own data, make sure to follow our <span id="formatting-link" class="link-like">formatting guidelines.</span></p>
            </div>

            <form id="form-analyze" enctype="multipart/form-data">

                <div id="step-1">

                    <div id="dataset-section">
                        <div id="user-data">


                            <fieldset>
                                <legend>Custom datasets:</legend>

                                <table id="upload-fields">
                                    <tr>
                                        <td>
                                            <input type="file" name="file_expression[]" id="file-expression-0" class="inputfile file-expression" accept=".csv, .txt, .tsv" />
                                            <label for="file-expression-0"><span>Click to select <br> expression data</span></label>

                                            <input type="file" name="file_clinical[]" id="file-clinical-0" class="inputfile file-clinical" accept=".csv, .txt, .tsv" />
                                            <label for="file-clinical-0"><span>Click to select <br> clinical data</span></label>
                                        </td>
                                        <td id="placeholder-remove-dataset"></td>
                                    </tr>
                                </table>

                                <button type="button" name="add_upload_field" id="add-upload-field"><span>+</span> <span>Add another dataset</span></button>

                            </fieldset>
                        </div>

                        <div id="preprocessed-data">
                            <fieldset>
                                <legend>Preprocessed datasets:</legend>
                                <div>
                                    <div class="checkbox">
                                        <input type="checkbox" class="demo-dataset" name="use_r2" id="use-r2" />
                                        <label for="use-r2">R2 (Neuroblastoma)</label>
                                    </div>
                                    <div class="dataset-description">
                                        <span>#Patients: 88</span>
                                        <br>
                                        <a target="_blank" rel="noopener noreferrer" href="https://www.nature.com/articles/nature10910">Go to source</a>
                                        <br>
                                        <a href="/data/r2_data.zip" download>Download processed data</a>
                                    </div>
                                </div>

                                <div>
                                    <div class="checkbox">
                                        <input type="checkbox" class="demo-dataset" name="use_target" id="use-target" />
                                        <label for="use-target">TARGET (Neuroblastoma)</label>
                                    </div>
                                    <div class="dataset-description">
                                        <span>#Patients: 249</span>
                                        <br>
                                        <a target="_blank" rel="noopener noreferrer" href="https://ocg.cancer.gov/programs/target">Go to source.</a>
                                        <br>
                                        <a href="/data/target_data.zip" download>Download processed data</a>
                                    </div>
                                </div>
                                <div>
                                    <div class="checkbox">
                                        <input type="checkbox" class="demo-dataset" name="use_SEQC" id="use-SEQC" />
                                        <label for="use-SEQC">SEQC (Neuroblastoma)</label>
                                    </div>
                                    <div class="dataset-description">
                                        <span>#Patients: 498</span>
                                        <br>
                                        <a target="_blank" rel="noopener noreferrer" href="https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE49711">Go to source.</a>
                                        <br>
                                        <a href="/targettranslator/data/SEQC_data.zip" download>Download processed data</a>
                                    </div>
                                </div>
                                <div>
                                    <div class="demo-dataset-group-title">
                                        <i class="arrow down"></i>
                                        <span>TCGA, Pan-Cancer</span>
                                    </div>
                                    <div class="dataset-description">
                                        <a target="_blank" rel="noopener noreferrer" href="https://cancergenome.nih.gov/">Go to source</a>
                                    </div>
                                </div>


                                <div class="demo-dataset-group">
                                <?php
                                // get information about all pancan datasets
                                $file_handle = fopen("data/pancan_info.csv","r");
                                while (!feof($file_handle) ) {
                                    $pancan_metadata[] = fgetcsv($file_handle);
                                }
                                fclose($file_handle);
                                // print all pancan datasets, skip title row
                                foreach(array_slice($pancan_metadata, 1) as $row) {
                                    $cancer_abbr = $row[0];
                                    $cancer_type = $row[1];
                                    $num_patients = $row[2];
                                    ?>

                                    <div>
                                        <div class="checkbox">
                                            <input type="checkbox" class="demo-dataset" name="use_<?php echo $cancer_abbr; ?>" id="use-<?php echo $cancer_abbr; ?>_Pan-Can"  />
                                            <label for="use-<?php echo $cancer_abbr; ?>_Pan-Can"><?php echo $cancer_abbr; ?></label>
                                        </div>
                                        <div class="dataset-description">
                                            <span>(<?php echo $cancer_type; ?>)</span>
                                            <br>
                                            <span>#Patients: <?php echo $num_patients; ?></span>
                                            <br>
                                            <a href="/data/<?php echo $cancer_abbr; ?>_Pan-Can_data.zip" download>Download processed data</a>
                                        </div>
                                    </div>

                                <?php } ?>

                                </div>
                   <!-- $mediums = get_growth_mediums();
                    $patient_mediums = array();
                    while ($row = fetch_array($patient_sample_cultures)) {
                        $patient_mediums[$row['medium_name']] = $row['passage'];
                    }
                    while ($row = fetch_array($mediums)) {
                        $medium_id = $row['growth_medium_id'];
                        $medium_name = $row['name'];
                        ?>
                                <div class="form-row">
                                    <div class="input-field width-150">
                                        <input type="checkbox"
                                               class="filled-in has-value"
                                               id="add-culture-medium-<?php /*echo $medium_id; */?>"
                                               name="culture_medium"
                                               value="<?php /*echo $medium_id; */?>"
                                            <?php /*if(array_key_exists($medium_name, $patient_mediums)) {echo "checked";} */?>
                                               onclick="ShowHideFormOptions(this)"
                                        />
                                        <label for="add-culture-medium-<?php /*echo $medium_id; */?>"><?php /*echo $medium_name; */?></label>
                                        <div class="input-error"></div>
                                    </div>
                                    <div class="input-field width-140 transparent-content">
                                        <input type="number"
                                               id="add-culture-passage-<?php /*echo $medium_id; */?>"
                                               name="culture_passage"
                                               value="<?php /*if(array_key_exists($medium_name, $patient_mediums)) {echo $patient_mediums[$medium_name];} else {echo "";} */?>"
                                        />
                                        <label for="add-culture-passage-<?php /*echo $medium_id; */?>">Highest passage</label>
                                        <div class="input-error"></div>
                                    </div>
                                </div>
                                --><?php /*} */?>


                            </fieldset>
                        </div>
                    </div>

                </div>

                <div id="step-2">

                    <h2>2. Define your risk groups</h2>
                    <div class="instructions">
                        <p>
                            What would you consider a risk group? Mark all factors that makes sense to you. Together,
                            they will be used to create the gene signature. The selected variables will be highlighted
                            in the heatmap below, while deselected variables are toned down in a darker color. High
                            values are represented with a higher intensity of the color.
                        </p>
                    </div>

                    <div id="risk-group-type-container">

                        <div class="radiobutton">
                            <input type="radio" id="type-clinical" name="risk-type-radio" checked>
                            <label for="type-clinical">define by clinical</label>
                        </div>

                        <div class="radiobutton">
                            <input type="radio" id="type-gene" name="risk-type-radio">
                            <label for="type-gene">define by genes</label>
                        </div>

                    </div>

                    <div id="stratification-section">

                        <div>
                            [No dataset has been selected]
                        </div>

                        <div class="scroll-wrapper">
                            <div id="select-stratifications"></div>
                        </div>

                        <div id="differentiation-markers-wrapper">

                            <!--<div class="checkbox">
                                <input type="checkbox" name="use_markers" id="use-markers" value="markers" />
                                <label for="use-markers">add differentiation markers</label>
                            </div>-->

                            <div id="differentiation-markers">
                                <div>
                                    <label for="markers-positive">up-regulated</label>
                                    <textarea id="markers-positive" placeholder="e.g.&#x0a;MTOR&#x0a;MFKS&#x0a;LKSLE&#x0a;..."></textarea>
                                </div>
                                <div>
                                    <label for="markers-negative" >down-regulated</label>
                                    <textarea id="markers-negative" placeholder="e.g.&#x0a;MTOR&#x0a;MFKS&#x0a;LKSLE&#x0a;..."></textarea>
                                </div>
                            </div>

                        </div>

                    </div>

                    <div id="heatmap-section">

                        <div id="filter-heatmap">

                        </div>

                        <div class="loading-section">
                            <div id="heatmap-loader">

                            </div>
                        </div>

                        <div class="filter-error"></div>
                    </div>

                </div>


                <div id="step-3-4">

                    <h2>3. Algorithm settings </h2>
                    <div class="instructions">
                        <p>Is survival time a part of your definition of a risk group? Then it might
                            be a good idea to take censoring effects into consideration. To do that,
                            check the checkbox below and specify where to find the survival time
                            and the censoring variable in your dataset. <!--What is really happening behind
                            the scene here? Read the <a href="#">documentation</a> and find out.-->
                    </div>

                    <div id="settings-section">

                        <div class="checkbox">
                            <input type="checkbox" name="run_cox" id="run-cox" />
                            <label for="run-cox">Use a Cox proportional hazards model</label>
                        </div>

                        <div id="cox-options">
                            <div id="select-survival">
                                <div class="stratification-row">
                                    <p>Survival time: </p>
                                    <select name="survival_time" id="survival-time">
                                        <option value="" disabled selected>Choose your option</option>
                                    </select>
                                </div>
                            </div>
                            <div id="select-life">
                                <div class="stratification-row">
                                    <p>Life status: </p>
                                    <select  name="is-alive" id="is-alive">
                                        <option value="" disabled selected>Choose your option</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>


                    <div id="submit-section">

                        <h2>4. All is set, time for analysis </h2>

                        <div class="instructions">
                            <p>This is your configuration. Read through it to make sure it is correct.</p>
                        </div>

                        <div id="analysis-summary">

                            <div id="summary-datasets" class="row">
                                <div>
                                    Datasets (expression/clinical):
                                </div>
                                <div>
                                    undefined
                                </div>
                                <div>
                                    undefined
                                </div>
                            </div>
                            <div id="summary-risk-group" class="row">
                                <div>
                                    Risk group definition:
                                </div>
                                <div>
                                    undefined
                                </div>
                            </div>
                            <div id="summary-settings" class="row">
                                <div>
                                    Survival
                                </div>
                                <div>
                                    No
                                </div>
                            </div>

                        </div>

                        <div id="submit">
                            <div id="progress-bar">
                                <div id="progress-fill">
                                    <div id="progress-text">Find my targets</div>
                                </div>
                            </div>
                        </div>

                    </div>

                    <div class="input-error"></div>
                </div>

            </form>

        </div>

        <div id="result-section">

            <h1>Time to dig into the results...</h1>

            <div id="score-container">
                <div class="center-container columns">

                    <div>

                        <div class="table-box">
                            <table id="result-table" class="highlight">
                                <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>Perturbation</th>
                                    <th>Score</th>
                                    <th>FDR</th>
                                    <th>Direction</th>
                                </tr>
                                </thead>

                                <tbody>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="information">
                        <h2>Drug Scores </h2>
                        <p>
                            This table tells you what drugs are most likely to induce the
                            change you wanted to investigate.
                        </p>
                        <p>Example:</p>
                        <p>
                            Let's say you have a variable x that can take on the values 0 and 1,
                            corresponding to low and high risk respectively. Then the table will
                            contain the drugs that will most likely change a high risk gene
                            signature to a low risk gene signature (direction: positive) and
                            vice versa.
                        </p>
                    </div>

                </div>
            </div>

            <div id="enrichment-container">
                <div class="center-container columns">

                    <div class="information">
                        <h2>Protein target enrichment</h2>
                        <p>
                            This table contains protein targets as defined by the STITCH
                            database. The top ranking targets are those that seems to be
                            enriched in the drug scoring table.
                        </p>
                        <p>
                            Each target has an associated empirical cumulative distribution functions (ECDF), visible when
                            hovering the target row. This makes it easy to compare the ECDF
                            of the target and the ECDF of all other targets.
                        </p>
                    </div>

                    <div>
                        <div class="table-box">
                            <table id="enrichment-table" class="highlight">
                                <thead>
                                <tr>
                                    <th>Target</th>
                                    <th>D-value</th>
                                    <th>p-value</th>
                                    <th>Direction</th>
                                </tr>
                                </thead>

                                <tbody>
                                </tbody>
                            </table>
                        </div>
                    </div>

                </div>
            </div>

        </div>

    </div>



    <div id="documentation" class="component ">
        <div class="top-stripe"></div>
        <div class="back-button" onclick="showComponent('landing')">
            <i class="back-arrow"></i>
            <span>Back</span>
        </div>

        <div class="center-container">
            <h2>Documentation</h2>

            <p>link to FAQ</p>
            <p>link to videos</p>
            <p>link to heavy documentation</p>
            <p>link to algorithm overview</p>

            <p>
                Troubleshooting <br>
                Please make sure that you data is correctly formatted, i.e. with unique row and column identifiers. <br>
                If cox seems fishy, decrease the selected stratifications to below 20.
            </p>
            <p>
                Make sure that your expression values are normally distributed, otherwise,
                try to log2 transform the data before submitting them for analysis.
            </p>

        </div>

    </div>

    <div id="rpackage" class="component">
        <div class="top-stripe"></div>
        <div class="back-button" onclick="showComponent('landing')">
            <i class="back-arrow"></i>
            <span>Back</span>
        </div>

        <div class="center-container">
            <h2>R package</h2>

            <p>download the r package</p>
            <p>give link to cran repository</p>
            <p>link to user guide for the package</p>
            <p>link to publication</p>

        </div>

    </div>

    <div id="contact" class="component ">
        <div class="top-stripe"></div>
        <div class="back-button" onclick="showComponent('landing')">
            <i class="back-arrow"></i>
            <span>Back</span>
        </div>

        <div class="center-container">
            <h2>About Us</h2>

            <p>link to the group website</p>
            <p>some contact information</p>

        </div>

    </div>





</div>



<!-- modal file formatting -->
<div id="modal-formatting" class="modal">

    <!-- Modal content -->
    <div class="modal-content">

        <span class="close">&times;</span>
        <h1>Formatting Guidelines</h1>
        <p>
            When uploading you own data to the targetTranslator web tool, you must preprocess
            the data into the correct format. One dataset consists of two files; one containing
            clinical variables (e.g. age, survival time, mutations) and one containing log2
            transformed expression values. Values in the files must be separated with tabs.
        </p>
        <p>
            The clinical file must consist of numerical values only, with the exception of
            column and row headers. To make interpretation easier, define indicator variables
            in terms of risk, e.g. high risk being 1 and low risk being 0, instead of mutation
            present being 1 and mutation absent being 0. When doing this, the direction
            parameter in the results will be more intuitive.
        </p>
        <p>
            The expression file should contain log2 transformed expression values. Gene
            identifiers (gene symbols) must follow the standards designated by the HUGO Gene
            Nomenclature Committee.
        </p>
        <p>
            Also, make sure that patient identifiers match between the two files. Non-matching
            patient identifiers will be removed from the dataset.
        </p>
        <p>
            To gain more control over the preprocessing step, make sure to impute any missing
            values before uploading you dataset. If you do not do this, the
            <a target="_blank" href="https://cran.r-project.org/web/packages/mice/index.html" >R-package mice</a>
            will be used for this purpose.
        </p>

        <br><br><br>

        <div id="example-files">
            <div class="table-fading-container">
                <span>example: clinical file</span>
                <div class="table-fading"></div>
                <table>
                    <tr>
                        <td class="table-header">patientID</td>
                        <td class="table-header">ALKmut</td>
                        <td class="table-header">MYCN</td>
                        <td class="table-header">age</td>
                        <td class="table-header">deletion11q</td>
                        <td class="table-header">gain17q</td>
                    </tr>
                    <tr>
                        <td class="table-header">PAAPFA</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1762</td>
                        <td>1</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACLJN</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1475</td>
                        <td>0</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACPJG</td>
                        <td>0</td>
                        <td>1</td>
                        <td>760</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACRYY</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1314</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACRZM</td>
                        <td>0</td>
                        <td>0</td>
                        <td>3686</td>
                        <td>1</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACSNL</td>
                        <td>0</td>
                        <td>0</td>
                        <td>2157</td>
                        <td>0</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACSSR</td>
                        <td>0</td>
                        <td>0</td>
                        <td>565</td>
                        <td>0</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACUGP</td>
                        <td>0</td>
                        <td>0</td>
                        <td>773</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACVNB</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1610</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACYGY</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1509</td>
                        <td>0</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PACZPX</td>
                        <td>0</td>
                        <td>0</td>
                        <td>1046</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                    <tr>
                        <td class="table-header">PADENF</td>
                        <td>0</td>
                        <td>0</td>
                        <td>987</td>
                        <td>1</td>
                        <td>0</td>
                    </tr>
                    <tr>
                        <td class="table-header">PADFLI</td>
                        <td>0</td>
                        <td>0</td>
                        <td>557</td>
                        <td>0</td>
                        <td>1</td>
                    </tr>
                </table>
            </div>

            <div class="table-fading-container">
                <span>example: expression file</span>
                <div class="table-fading"></div>
                <table>
                    <tr>
                        <td class="table-header">gene</td>
                        <td class="table-header">PAAPFA</td>
                        <td class="table-header">PACLJN</td>
                        <td class="table-header">PACPJG</td>
                        <td class="table-header">PACRYY</td>
                        <td class="table-header">PACRZM</td>
                    </tr>
                    <tr>
                        <td class="table-header">A1BG</td>
                        <td>6.78909</td>
                        <td>6.88369</td>
                        <td>7.01703</td>
                        <td>6.64956</td>
                        <td>7.14398</td>
                    </tr>
                    <tr>
                        <td class="table-header">A1CF</td>
                        <td>4.26056</td>
                        <td>4.07803</td>
                        <td>4.18637</td>
                        <td>3.91235</td>
                        <td>4.27182</td>
                    </tr>
                    <tr>
                        <td class="table-header">A2M</td>
                        <td>9.48526</td>
                        <td>9.05439</td>
                        <td>8.85148</td>
                        <td>9.05921</td>
                        <td>8.8002</td>
                    </tr>
                    <tr>
                        <td class="table-header">A2ML1</td>
                        <td>4.291</td>
                        <td>4.50925</td>
                        <td>4.45102</td>
                        <td>4.2867</td>
                        <td>4.34483</td>
                    </tr>
                    <tr>
                        <td class="table-header">A4GALT</td>
                        <td>6.79195</td>
                        <td>7.01082</td>
                        <td>6.93226</td>
                        <td>6.67259</td>
                        <td>6.9787</td>
                    </tr>
                    <tr>
                        <td class="table-header">A4GNT</td>
                        <td>5.03762</td>
                        <td>5.13415</td>
                        <td>4.76195</td>
                        <td>4.66682</td>
                        <td>5.16944</td>
                    </tr>
                    <tr>
                        <td class="table-header">AAAS</td>
                        <td>8.40981</td>
                        <td>8.54223</td>
                        <td>8.59114</td>
                        <td>8.95412</td>
                        <td>9.04687</td>
                    </tr>
                    <tr>
                        <td class="table-header">AACS</td>
                        <td>8.01635</td>
                        <td>7.33654</td>
                        <td>7.51486</td>
                        <td>8.4847</td>
                        <td>7.85762</td>
                    </tr>
                    <tr>
                        <td class="table-header">AACSP1</td>
                        <td>7.81474</td>
                        <td>7.47532</td>
                        <td>7.66324</td>
                        <td>9.36748</td>
                        <td>8.49826</td>
                    </tr>
                    <tr>
                        <td class="table-header">AADAC</td>
                        <td>3.02507</td>
                        <td>3.23404</td>
                        <td>3.23881</td>
                        <td>2.68007</td>
                        <td>3.15637</td>
                    </tr>
                    <tr>
                        <td class="table-header">AADACL2</td>
                        <td>3.5635</td>
                        <td>3.53766</td>
                        <td>3.40314</td>
                        <td>2.8606</td>
                        <td>3.57186</td>
                    </tr>
                    <tr>
                        <td class="table-header">AADAT</td>
                        <td>6.76541</td>
                        <td>6.49705</td>
                        <td>6.8701</td>
                        <td>7.05731</td>
                        <td>6.95924</td>
                    </tr>
                    <tr>
                        <td class="table-header">AAGAB</td>
                        <td>7.36289</td>
                        <td>7.49427</td>
                        <td>7.25862</td>
                        <td>7.24782</td>
                        <td>7.15615</td>
                    </tr>
                </table>
            </div>
        </div>

    </div>

</div>






<!-- JQuery -->
<script src="/_plugins/jquery-3.3.1.min.js"></script>

<!-- Particles -->
<script src="/_plugins/particles/particles.min.js"></script>

<!-- PapaParse -->
<script src="/_plugins/papaparse/papaparse.min.js"></script>

<!-- Bootstrap tour -->
<script src="/_plugins/bootstrap-tour/bootstrap-tour-standalone.min.js"></script>

<!-- JavaScript Custom -->
<script src="/_js/script.js"></script>




</body>
</html>
