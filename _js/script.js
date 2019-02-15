
// ======================================================= print stratification checkboxes

function findIntersectingHeaders(headers) {

    // flatten array of arrays
    let mergedHeaders = [].concat.apply([], headers);

    // sort array
    mergedHeaders.sort();
    let a = [], b = [], prev;

    // count frequency of each value in the array
    for (let i = 0; i < mergedHeaders.length; i++) {
        if (mergedHeaders[i] !== prev) {
            a.push(mergedHeaders[i]);
            b.push(1);
        } else {
            b[b.length-1]++;
        }
        prev = mergedHeaders[i];
    }

    // get headers that occur the same number of times as
    // the number of datasets, i.e. that exists in all datasets
    let commonHeaders = [];
    for (let i = 0; i < b.length; i++) {
        if (b[i] === headers.length) {
            commonHeaders.push(a[i]);
        }
    }

    // find an return unique headers
    return [...new Set(commonHeaders)];

}

function printStratificationCheckboxes(variableNames) {

    const stratificationSection = $("#stratification-section");
    const stratificationContainer = $("#select-stratifications");
    const stratificationWrapper = $(".scroll-wrapper");
    const differentiationMarkersWrapper = $("#differentiation-markers-wrapper");
    const riskGroupTypeContainer = $("#risk-group-type-container");

    // hide message about no datasets
    stratificationSection.children(":first").css("display", "none");

    // remove all previous options if any
    stratificationContainer.empty();

    // empty text areas for differentiation markers and hide checkbox
    $("#differentiation-markers").find("textarea").empty();
    differentiationMarkersWrapper.css("display", "none");

    // hide risk group type radio buttons
    riskGroupTypeContainer.css("display", "none");

    // hide stratification checkboxes
    stratificationWrapper.css("display", "none");

    // remove heatmap
    $("#filter-heatmap").empty();

    // if no variables
    if (variableNames === null) {
        //show message about it
        stratificationSection.children(":first").css("display", "block");
        return;
    }

    // create and add options to the select-boxes
    $.each(variableNames, function (index, row) {

        // check if value exists, if not, stop printing
        if (!row) {
            return false;
        }

        // globally replace non-alphanumeric characters and white spaces with underscores
        // and transform letters to lowercase
        // maybe one shouldn't do this...
        //row[0] = row[0].replace(/[\W_]/g, "_").toLowerCase();

        // add checkboxes for each stratification
        stratificationContainer
            .append(
                '<div class="checkbox">' +
                '   <input type="checkbox" name="stratifications[]" id="' + row + '" value="' + row + '"/>' +
                '   <label for="' + row + '">' + row + '</label>' +
                '</div>'
            );

    });

    //differentiationMarkersWrapper.css("display", "block");
    stratificationWrapper.css("display", "block");
    riskGroupTypeContainer.css("display", "flex");

}

function printSurvivalOptions(variableNames) {

    const selectSurvival = $("#select-survival").find("select");
    const selectLife = $("#select-life").find("select");

    // remove all options in the survival select-boxes
    selectSurvival.empty().append($('<option value="" disabled selected>Choose your option</option>'));
    selectLife.empty().append($('<option value="" disabled selected>Choose your option</option>'));

    // uncheck the survival checkbox
    $("#run-cox").prop("checked", false);

    // create and add options to the select-boxes
    $.each(variableNames, function (index, row) {

        // check if value exists, if not, stop printing
        if (!row) {
            return false;
        }

        // add values to the select boxes in settings (survival and isAlive)
        $("#select-survival").find("select")
            .append($("<option></option>")
                .attr("value", row)
                .text(row)
            );
        $("#select-life").find("select")
            .append($("<option></option>")
                .attr("value", row)
                .text(row)
            );

    });

}

// ===================================================================== toggle components

function showComponent(componentName) {
    // Declare all variables
    let components;

    // Get all elements with class="component" and hide them
    components = document.getElementsByClassName("component");
    for (let i = 0; i < components.length; i++) {
        components[i].style.display = "none";
    }

    // Show the current component
    document.getElementById(componentName).style.display = "block";
}


// ===================================================================== increase progress

function increaseProgress() {
    let fill = document.getElementById("progress-fill");
    let text = $("#progress-text");

    let width = 0.01;
    let id = setInterval(frame, 100);

    function frame() {

        let breakProgress = Boolean(text.html() === "Find my targets");

        // update width
        // note! it should not reach 100% here, this should happen when
        // everything is actually finished
        if ((width >= 99 && width < 100) || breakProgress) {
            clearInterval(id);
        } else {
            width = width + 0.1;
            fill.style.width = width + '%';
        }

        // update progress text
        if (breakProgress) {
            // do nothing
        } else if(width < 1) {
            text.html("uploading data...");
        } else if(width < 10) {
            text.html("validating files...");
        } else if(width < 20) {
            text.html("preprocessing data...");
        } else if(width < 30) {
            text.html("creating signatures...");
        } else if(width < 40) {
            text.html("loading L1000...");
        } else if(width < 50) {
            text.html("estimating scores...");
        } else if(width < 60) {
            text.html("estimating enrichment...");
        } else if(width < 70) {
            text.html("collecting results...");
        }
    }
}


// ======================================================================== document ready

$(document).ready(function () {

    // ========================================================================= particles

    /* particlesJS.load(@dom-id, @path-json, @callback (optional)); */
    particlesJS.load('particles-js', '/targettranslator/_plugins/particles/particles.json', function() {
        console.log('callback - particles.js config loaded');
    });


    // ======================================================================== reset form

    $(".back-button").on("click", function() {

        // empty form
        document.getElementById("form-analyze").reset();

        // empty stratification checkboxes
        const stratificationContainer = $("#select-stratifications");
        stratificationContainer.empty();
        stratificationContainer.find("#gene-box").empty();
        stratificationContainer.append('<div> <p>[No dataset has been selected]</p> </div>');

        // remove heatmap
        $("#filter-heatmap").empty();

        // hide dynamic options
        $("#cox-options").css("display", "none");

    });


    // ========================================================== handle dataset selection

    // When the user clicks on the down arrow for a demo dataset group, transform to up
    $(".demo-dataset-group-title").on("click", function() {

        if($("i.arrow").hasClass("down")) {

            // change direction of arrow
            $("i.arrow").removeClass( "down" ).addClass( "up" );

            // hide all pancan datasets
            $(".demo-dataset-group").css("display", "block");

        } else {
            // change direction of arrow
            $("i.arrow").removeClass( "up" ).addClass( "down" );

            // show all pancan datasets
            $(".demo-dataset-group").css("display", "none");
        }

    });

    $(document).on("change", ".file-clinical, .demo-dataset", function() {

        // collect uploaded files
        let uploadedFiles = [];
        $('.file-clinical').each(function () {
            if ($(this)[0].files[0] !== undefined) {
                uploadedFiles.push($(this)[0].files[0]);
            }
        });

        // collect selected demo datasets
        let selectedDemoDatasets = [];
        $(".demo-dataset:checked").each(function () {
            selectedDemoDatasets.push($(this).attr("id").substring(4));
        });

        // preallocate array for stratification names
        let allHeaders = [];

        // print stratification checkboxes
        if (selectedDemoDatasets.length === 0 && uploadedFiles.length === 0) {
            // if no datasets are selected

            // remove checkboxes
            printStratificationCheckboxes(null);

            // remove survival options
            printSurvivalOptions(null);

        } else if (selectedDemoDatasets.length > 0 && uploadedFiles.length > 0) {
            // if any file input boxes are selected AND demo datasets are selected

            // File datasets
            for (let i = 0; i < uploadedFiles.length; i++) {

                Papa.parse(uploadedFiles[i], {
                    download: true,
                    preview: 1,
                    error: function(err, file, inputElem, reason) { /* handle*/ },
                    complete: function(results) {

                        // extract variable names and put into array
                        let headers = results.data[0];

                        // remove the first header ("Row" for patient identifiers)
                        headers.shift();

                        allHeaders.push(headers);

                        if (allHeaders.length === uploadedFiles.length) {
                            // all uploaded files have been parsed

                            // download demo datasets
                            for (let j = 0; j < selectedDemoDatasets.length; j++) {

                                $.getJSON("data/" + selectedDemoDatasets[j] + "_clinical.json", function(data) {

                                    // extract variable names and put into array
                                    let headers = Object.keys(data[0]);

                                    // remove the first header ("Row" for patient identifiers)
                                    headers.shift();

                                    allHeaders.push(headers);

                                    if (allHeaders.length === selectedDemoDatasets.length + selectedDemoDatasets.length) {

                                        // find headers that exists in all datasets
                                        let commonHeaders = findIntersectingHeaders(allHeaders);

                                        // print stratification boxes
                                        printStratificationCheckboxes(commonHeaders);

                                        // print survival options
                                        printSurvivalOptions(commonHeaders);

                                    }
                                });
                            }
                        }

                    }
                });

            }


        } else if (selectedDemoDatasets.length > 0) {
            // if any demo-datasets are selected, download dataset (or only headers?) from server

            // find total number of datasets
            let numDatasets = selectedDemoDatasets.length;

            for (let i = 0; i < selectedDemoDatasets.length; i++) {

                $.getJSON("data/" + selectedDemoDatasets[i] + "_clinical.json", function(data) {

                    // extract variable names and put into array
                    let headers = Object.keys(data[0]);

                    // remove the first header ("Row" for patient identifiers)
                    headers.shift();

                    allHeaders.push(headers);

                    if (allHeaders.length === numDatasets) {

                        // find headers that exists in all datasets
                        let commonHeaders = findIntersectingHeaders(allHeaders);

                        // print stratification boxes
                        printStratificationCheckboxes(commonHeaders);

                        // print survival options
                        printSurvivalOptions(commonHeaders);

                    }
                });
            }

        } else if (uploadedFiles.length > 0) {
            // uploaded files

            // find total number of datasets
            let numDatasets = uploadedFiles.length;

            for (let i = 0; i < uploadedFiles.length; i++) {

                Papa.parse(uploadedFiles[i], {
                    download: true,
                    preview: 1,
                    error: function(err, file, inputElem, reason) { /* handle*/ },
                    complete: function(results) {

                        // extract variable names and put into array
                        let headers = results.data[0];

                        // remove the first header ("Row" for patient identifiers)
                        headers.shift();

                        allHeaders.push(headers);

                        if (allHeaders.length === numDatasets) {
                            console.log(allHeaders);
                            // find headers that exists in all datasets
                            let commonHeaders = findIntersectingHeaders(allHeaders);

                            // print stratification boxes
                            printStratificationCheckboxes(commonHeaders);

                            // print survival options
                            printSurvivalOptions(commonHeaders);

                        }
                    }
                });

            }
        }


        // toggle visibility of step 2
        if (selectedDemoDatasets.length !== 0 || uploadedFiles.length !== 0) {
            // if at least one dataset has been uploaded or selected, show step 2

        } else {
            // hide step 2
        }


    });


    // ===================================================== add/delete file upload fields

    let uploadFileCounter = 1;
    $('#add-upload-field').click(function() {
        uploadFileCounter++;
        $("#upload-fields").append(
            '<tr id="row' + uploadFileCounter + '">' +
            '<td>' +
            '<input type="file" name="file_expression[]" id="file-expression-' + uploadFileCounter + '" class="inputfile file-expression" accept=".csv, .txt, .tsv" />' +
            '<label for="file-expression-' + uploadFileCounter + '"><span>Click to select <br> expression data</span></label>' +

            '<input type="file" name="file_clinical[]" id="file-clinical-' + uploadFileCounter + '" class="inputfile file-clinical" accept=".csv, .txt, .tsv" />' +
            '<label for="file-clinical-' + uploadFileCounter + '"><span>Click to select <br> clinical data</span></label>' +
            '</td>' +
            '<td>' +
            '<button type="button" name="remove-upload-field" id="' + uploadFileCounter + '" class="remove-upload-field">' +
            '</button>' +
            '</td>' +
            '</tr>'
        );
    });

    $(document).on('click', '.remove-upload-field', function(){
        let buttonId = $(this).attr("id");
        $('#row' + buttonId + '').remove();
    });

    // =========================================================== change file input areas

    document.getElementById("upload-fields").addEventListener("change", function(e) {
        // e.target is the clicked element
        // if it was an input element
        if(e.target && e.target.nodeName === "INPUT") {

            // extract values
            let fileName = "";
            let input = e.target;
            let label = input.nextElementSibling;
            let labelVal = label.innerHTML;
            let dataType;
            if (label.innerText.includes("clinical")) {
                dataType = "clincial"
            } else {
                dataType = "expression"
            }

            // if file was selected, extract file name
            if(e.target.value) {
                fileName = '<span class="file-name">Selected ' + dataType + ' data: <br>' + e.target.value.split( "\\" ).pop() + '</span>';
            }

            // update label text
            if (fileName) {
                label.innerHTML = fileName;
            } else {
                label.innerHTML = '<span>Click to select <br> ' + dataType + ' data</span>';
            }

        }
    });


    // ============================================================= create filter heatmap

    let currentRequest = null;
    $(document).on("click", "input[name='stratifications[]']", function() {

        // hide error box
        let errorContainer = $("div.filter-error");
        errorContainer.empty();
        errorContainer.css("display", "none");

        // create a formData object
        let formData = new FormData();

        // collect selected variables
        let stratifications = [];
        $("input[name='stratifications[]']:checked").each(function () {
            stratifications.push($(this).val());
        });

        // if no stratifications are selected, return
        if (stratifications.length === 0) {
            // remove images if there are any
            $("#filter-heatmap").empty();
            return;
        }

        // add stratifications to formData
        formData.append("stratifications", JSON.stringify(stratifications));

        // add demo dataset names to formData to get files from server.
        if ($('.demo-dataset').is(":checked")) {

            // collect selected demo datasets
            let selectedDatasets = [];
            $(".demo-dataset:checked").each(function() {
                selectedDatasets.push(this.id.substring(4));
            });

            formData.append("demo_datasets", JSON.stringify(selectedDatasets));
        }

        // add clinical files to formData
        $(".file-clinical").each(function () {
            if ($(this)[0].files[0] !== undefined) {
                //clinicalFiles.push($(this)[0].files[0]);
                formData.append("files_clinical[]", $(this)[0].files[0]);
            }
        });

        // show loading circle
        $(".loading-section").css("visibility", "visible");

        // send to Rscript
        // note hax to abort previous ajax call if new one is requested before the old finishes
        // TODO: does not work https://arjunphp.com/abort-previous-ajax-request-jquery/
        currentRequest = $.ajax({
            type        : 'POST',
            url         : 'server/create_heatmap.php',
            data        : formData,
            processData: false, // NEEDED, DON'T OMIT THIS
            contentType: false, // NEEDED, DON'T OMIT THIS (requires jQuery 1.6+)
            //dataType    : 'json',
            encode      : true,
            beforeSend : function() {
                if(currentRequest != null) {
                    currentRequest.abort();
                }
            }
        })
            .done(function(data) { // using the done promise callback
                // ================================================ get result from server
                console.log("done heatmap");
                console.log(data);
                // hide loading circle
                $(".loading-section").css("visibility", "hidden");

                let errorContainer = $("div.filter-error");

                let result = JSON.parse(data);

                console.log(result);
                let wasSuccessful = result["success"];
                let validationErrors = result["validation_errors"];
                let rErrors = result["analysis_errors"];
                let rInformation = result["info"];
                let rData = result["data"];

                if (validationErrors != null) {

                    // show error box
                    errorContainer.css("display", "block");

                    // print validation errors
                    errorContainer.empty();

                    $.each(validationErrors, function(index, value) {
                        // use .text() instead of just writing the value to the <p> tag, so we're safe
                        // if the value contains <, etc.
                        errorContainer.append($('<p>').text("Validation Error: " + value));
                    });

                } else if (rErrors != null) {

                    // show error box
                    errorContainer.css("display", "block");

                    // print R errors
                    errorContainer.empty();

                    $.each(rErrors.slice(1), function(index, value) {
                        // use .text() instead of just writing the value to the <p> tag, so we're safe
                        // if the value contains <, etc.
                        errorContainer.append($('<p>').text("Analysis Error: " + value));
                    });

                } else if (wasSuccessful) {

                    if (rInformation != null) {
                        // TODO: print information from R
                    }

                    // remove images if there are any
                    $("#filter-heatmap").empty();

                    // add heatmap image
                    let base64StringEnrichment = rData[0].replace(/\s*\[\d\]\s*/, ""); // matches "  [1]  "
                    base64StringEnrichment = base64StringEnrichment.replace(/\"/, ""); // matches quotes

                    // $("#plots").append('<img src="data:image/png;base64,' + base64StringEnrichment + '" / >');
                    $("#filter-heatmap").append('<img src="data:image/png;base64,' + base64StringEnrichment + '/ >');

                } else {
                    // something bad happened...
                }

            })
            .always(function() {
                // remove loading image maybe
                console.log("always heatmap");
            })
            .fail(function(jqXHR, textStatus) {
                // handle request failures
                console.log("fail heatmap");
                console.log(textStatus);
            });

    });


    // ==================================================================== create summary

    // print datasets
    $(document).on("change", ".file-expression, .file-clinical, .demo-dataset", function() {

        let summaryDatasets = $("#summary-datasets");

        // empty current datasets
        summaryDatasets.find("div:nth-child(2)").empty();
        summaryDatasets.find("div:nth-child(3)").empty();

        // collect uploaded files
        let uploadedExpressionFiles = [];
        $('.file-expression').each(function () {
            if ($(this)[0].files[0] !== undefined) {
                uploadedExpressionFiles.push($(this)[0].files[0].name);
            }
        });

        // collect uploaded files
        let uploadedClinicalFiles = [];
        $('.file-clinical').each(function () {
            if ($(this)[0].files[0] !== undefined) {
                uploadedClinicalFiles.push($(this)[0].files[0].name);
            }
        });

        // collect selected demo datasets
        let selectedDemoDatasets = [];
        $(".demo-dataset:checked").each(function () {
            selectedDemoDatasets.push($(this).next("label").html());
        });

        // add demo datasets to the uploaded ones
        let expressionDatasets  = uploadedExpressionFiles.concat(selectedDemoDatasets);
        let clinicalDatasets = uploadedClinicalFiles.concat(selectedDemoDatasets);

        if (expressionDatasets.length === clinicalDatasets.length) {

            if (expressionDatasets.length === 0) {
                summaryDatasets.find("div:nth-child(2)").append('undefined <br>');
                summaryDatasets.find("div:nth-child(3)").append('undefined<br>');
            } else {
                for (let i = 0; i < expressionDatasets.length; i++) {
                    summaryDatasets.find("div:nth-child(2)").append(expressionDatasets[i] + '<br>');
                    summaryDatasets.find("div:nth-child(3)").append(clinicalDatasets[i] + '<br>');
                }
            }
        } else {
            // TODO: error
        }

    });

    // print stratifications
    $(document).on("click", "input[name='stratifications[]']", function() {

        let summaryRiskGroup = $("#summary-risk-group");

        // empty current stratifications
        summaryRiskGroup.find("div:nth-child(2)").empty();

        // collect risk group variables
        let stratifications = [];
        $("input[name='stratifications[]']:checked").each(function () {
            stratifications.push($(this).val());
        });

        // print risk groups
        if (stratifications.length === 0) {
            summaryRiskGroup.find("div:nth-child(2)").append('undefined<br>');
        } else {
            for (let i = 0; i < stratifications.length; i++) {
                summaryRiskGroup.find("div:nth-child(2)").append(stratifications[i] + '<br>');
            }
        }
    });

    // print settings
    $(document).on("change", "#run-cox", function() {

        let summarySettings = $("#summary-settings");

        // empty current settings
        summarySettings.find("div:nth-child(2)").empty();

        // collect risk group variables
        let cox = "No";
        if ($("#run-cox").is(':checked')) {
            cox = "Yes";
        }

        // print risk groups
        summarySettings.find("div:nth-child(2)").append(cox);

    });


    // ============================================================= process analysis form

    $(document).on("click", "#submit", function() {

        // TODO: Check form elements for errors
        // TODO: only if files are uploaded, else just send the json clinical data and name of dataset
        // TODO: if the user clicks the backbutton, all settings also must be cleared

        let text = $("#progress-text");

        // if button has transformed into progress bar, do nothing
        if (text.html() === "validating input...") {
            return;
        }

        // transform button to progress bar
        text.html("validating input...");
        let bar = $("#progress-bar");
        bar.css({"background-color": "#eaeaea", "color": "#000000", "cursor": "default"});

        // hide error box
        let errorContainer = $("div.input-error");
        errorContainer.empty();
        errorContainer.css("display", "none");

        // hide result section
        $("#result-section").css("display", "none");

        // check for errors
        // TODO: create error if no datasets are selected OR no datasets are uploaded
        // if ($(".demo-dataset:checked").length === 0) {
        //     // no datasets are selected
        //     errorContainer.css("display", "block");
        //     errorContainer.append($('<p>').text("Please select a dataset."));
        // }
        if ($("input[name='stratifications[]']:checked").length === 0 && !$.trim($("#markers-negative").val()) && !$.trim($("#markers-positive").val())) {
            // no stratifications are selected
            errorContainer.css("display", "block");
            errorContainer.append($('<p>').text("Please define your risk groups."));
        }

        // if any errors, reset and return
        if (errorContainer.html().trim()) {
            bar.css({"background-color": "rgba(84,77,162,1)", "color": "#ffffff", "cursor": "pointer"});
            text.html("Find my targets");
            return;
        }



        // get checked stratifications
        let stratifications = [];
        $("input[name='stratifications[]']:checked").each(function () {
            stratifications.push($(this).val());
        });

        // If cox is to be run, add survival and life status to the stratifications
        if ($('#run-cox').is(":checked")) {

            let survival = $('#survival-time').val();
            let alive = $('#is-alive').val();

            if (stratifications.indexOf(survival) === -1) {
                stratifications.push(survival);
            }

            if (stratifications.indexOf(alive) === -1) {
                stratifications.push(alive);
            }
        }

        // get gene weights, split for each new line, trim whitespace
        let markersNegative = $.map($("#markers-negative").val().split("\n"), $.trim);
        let markersPositive = $.map($("#markers-positive").val().split("\n"), $.trim);

        // create a formData object
        let formData = new FormData();

        // add demo dataset names to formData to get files from server.
        if ($('.demo-dataset').is(":checked")) {

            // collect selected demo datasets
            let selectedDatasets = [];
            $(".demo-dataset:checked").each(function() {
                selectedDatasets.push(this.id.substring(4));
            });

            formData.append("demo_datasets", JSON.stringify(selectedDatasets));
        }

        // add clinical files to formData
        $(".file-clinical").each(function () {
            if ($(this)[0].files[0] !== undefined) {
                formData.append("files_clinical[]", $(this)[0].files[0]);
            }
        });

        // add expression files to formData
        $(".file-expression").each(function () {
            if ($(this)[0].files[0] !== undefined) {
                formData.append("files_expression[]", $(this)[0].files[0]);
            }
        });

        // add stratifications to formData
        formData.append("stratifications", JSON.stringify(stratifications));

        // add genes to formData
        formData.append("markers_negative", JSON.stringify(markersNegative));
        formData.append("markers_positive", JSON.stringify(markersPositive));

        // add settings to formData
        formData.append("log_check", $('#log-check').is(":checked"));
        formData.append("run_cox", $('#run-cox').is(":checked"));
        formData.append("L1000_type", "drug");
        formData.append("survival", $('#survival-time').val());
        formData.append("is_alive", $('#is-alive').val());


        console.log(errorContainer);

        // start progress bar
        increaseProgress();




        // ====================================================== send form data to server
        $.ajax({
            type        : 'POST',
            url         : 'server/run_analysis.php',
            data        : formData,
            processData: false, // NEEDED, DON'T OMIT THIS
            contentType: false, // NEEDED, DON'T OMIT THIS (requires jQuery 1.6+)
            //dataType    : 'json',
            encode      : true
        })
            .done(function(data) { // using the done promise callback
                // ==================================================== get result from server

                bar.css({"background-color": "rgba(84,77,162,1)", "color": "#ffffff", "cursor": "pointer"});
                text.html("Find my targets");

                console.log("done");

                // reactive run button
                $("#run-button").removeClass("disabled");

                // show progress bar
                $("#progress-section").css("visibility", "hidden");

                let errorContainer = $("div.input-error");
                console.log(data);
                let result = JSON.parse(data);

                let wasSuccessful = result["success"];
                let validationErrors = result["validation_errors"];
                let rErrors = result["analysis_errors"];
                let rInformation = result["info"];
                let rData = result["data"];

                if (validationErrors != null) {

                    // show error box
                    errorContainer.css("display", "block");

                    // print validation errors
                    errorContainer.empty();

                    $.each(validationErrors, function(index, value) {
                        // use .text() instead of just writing the value to the <p> tag, so we're safe
                        // if the value contains <, etc.
                        errorContainer.append($('<p>').text("Validation Error: " + value));
                    });

                } else if (rErrors != null) {

                    // show error box
                    errorContainer.css("display", "block");

                    // print R errors
                    errorContainer.empty();

                    $.each(rErrors.slice(1), function(index, value) {
                        // use .text() instead of just writing the value to the <p> tag, so we're safe
                        // if the value contains <, etc.
                        errorContainer.append($('<p>').text("Analysis Error: " + value));
                    });

                } else if (wasSuccessful) {
                    //console.log(rData[1]);


                    // show result section
                    $("#result-section").css("display", "block");

                    if (rInformation != null) {
                        // print information from R
                    }

                    // RESULT TABLE

                    // remove old rows if there are any
                    $("#result-table").find($("tbody")).empty();

                    // add rows and fill with data
                    let tr;
                    for (let i = 0; i < rData[0].length; i++) {
                        // console.log(rData[0][i]);

                        tr = $('<tr/>');
                        // tr.append("<td>" + rData[0][i].signature + "</td>");
                        tr.append("<td>" + rData[0][i].rank + "</td>");
                        tr.append("<td>" + rData[0][i].perturbation + "</td>");
                        tr.append("<td>" + rData[0][i].score + "</td>");
                        tr.append("<td>" + rData[0][i].fdr + "</td>");
                        tr.append("<td>" + rData[0][i].direction + "</td>");
                        $("table#result-table").find($("tbody")).append(tr);
                    }


                    // ENRICHMENT TABLE
                    console.log(rData[0]);
                    console.log(rData[1]);

                    // remove old rows if there are any
                    $("#enrichment-table").find($("tbody")).empty();

                    // add rows and fill with data
                    for (let i = 0; i < rData[1].length; i++) {
                        //console.log(rData[1][i]);

                        tr = $('<tr class="view-plot" />');
                        tr.append("<td>" + rData[1][i].target + "</td>");
                        tr.append("<td>" + rData[1][i].dvalue + "</td>");
                        tr.append("<td>" + rData[1][i].pvalue + "</td>");
                        tr.append("<td>" + rData[1][i].direction + "</td>");
                        tr.append("<td>" + '<div class="hidden-plot"><img src="data:image/png;base64,' + rData[1][i].distribution + '" / >' + "</div></td>");
                        $("table#enrichment-table").find($("tbody")).append(tr);
                    }


                } else {
                    // something bad happened...
                }

            })
            .always(function() {
                // remove loading image maybe
                console.log("always");
            })
            .fail(function(jqXHR, textStatus) {
                // handle request failures
                console.log("fail");
                console.log(textStatus);
            });



    });

    /*$('#form-analyze').submit(function(event) {
        // stop the form from submitting the normal way and refreshing the page
        event.preventDefault();

        // TODO: Check form elements for errors
        // TODO: only if files are uploaded, else just send the json clinical data and name of dataset
        // TODO: if the user clicks the backbutton, all settings also must be cleared

        // hide error box
        let errorContainer = $("div.input-error");
        errorContainer.empty();
        errorContainer.css("display", "none");

        if ($(".demo-dataset:checked").length === 0) {
            // no datasets are selected
            errorContainer.css("display", "block");
            errorContainer.append($('<p>').text("Please select a dataset."));
        } else if ($("input[name='stratifications[]']:checked").length === 0) {
            // no stratifications are selected
            errorContainer.css("display", "block");
            errorContainer.append($('<p>').text("Please select at least one variable to stratify on."));
        } else {
            // no errors
            // get checked stratifications
            let stratifications = [];
            $("input[name='stratifications[]']:checked").each(function () {
                stratifications.push($(this).val());
            });

            // If cox is to be run, add survival and life status to the stratifications
            if ($('#run-cox').is(":checked")) {

                let survival = $('#survival-time').val();
                let alive = $('#is-alive').val();

                if (stratifications.indexOf(survival) === -1) {
                    stratifications.push(survival);
                }

                if (stratifications.indexOf(alive) === -1) {
                    stratifications.push(alive);
                }
            }

            // create a formData object
            let formData = new FormData();

            // add demo dataset names to formData to get files from server.
            if ($('.demo-dataset').is(":checked")) {

                // collect selected demo datasets
                let selectedDatasets = [];
                $(".demo-dataset:checked").each(function() {
                    selectedDatasets.push(this.id.substring(4));
                });

                formData.append("demo_datasets", JSON.stringify(selectedDatasets));
            }

            // add clinical files to formData
            $(".file-clinical").each(function () {
                if ($(this)[0].files[0] !== undefined) {
                    formData.append("files_clinical[]", $(this)[0].files[0]);
                }
            });

            // add expression files to formData
            $(".file-expression").each(function () {
                if ($(this)[0].files[0] !== undefined) {
                    formData.append("files_expression[]", $(this)[0].files[0]);
                }
            });

            // add stratifications to formData
            formData.append("stratifications", JSON.stringify(stratifications));

            // add settings to formData
            formData.append("log_check", $('#log-check').is(":checked"));
            formData.append("run_cox", $('#run-cox').is(":checked"));
            formData.append("L1000_type", "drug");
            formData.append("survival", $('#survival-time').val());
            formData.append("is_alive", $('#is-alive').val());

            // inactive run button
            $("#run-button").addClass("disabled");

            // show progress bar
            $("#progress-section").css("visibility", "visible");

            // ====================================================== send form data to server
            $.ajax({
                type        : 'POST',
                url         : 'server/run_analysis.php',
                data        : formData,
                processData: false, // NEEDED, DON'T OMIT THIS
                contentType: false, // NEEDED, DON'T OMIT THIS (requires jQuery 1.6+)
                //dataType    : 'json',
                encode      : true
            })
                .done(function(data) { // using the done promise callback
                    // ==================================================== get result from server

                    console.log("done");

                    // reactive run button
                    $("#run-button").removeClass("disabled");

                    // show progress bar
                    $("#progress-section").css("visibility", "hidden");

                    let errorContainer = $("div.input-error");
                    console.log(data);
                    let result = JSON.parse(data);

                    let wasSuccessful = result["success"];
                    let validationErrors = result["validation_errors"];
                    let rErrors = result["analysis_errors"];
                    let rInformation = result["info"];
                    let rData = result["data"];

                    if (validationErrors != null) {

                        // show error box
                        errorContainer.css("display", "block");

                        // print validation errors
                        errorContainer.empty();

                        $.each(validationErrors, function(index, value) {
                            // use .text() instead of just writing the value to the <p> tag, so we're safe
                            // if the value contains <, etc.
                            errorContainer.append($('<p>').text("Validation Error: " + value));
                        });

                    } else if (rErrors != null) {

                        // show error box
                        errorContainer.css("display", "block");

                        // print R errors
                        errorContainer.empty();

                        $.each(rErrors.slice(1), function(index, value) {
                            // use .text() instead of just writing the value to the <p> tag, so we're safe
                            // if the value contains <, etc.
                            errorContainer.append($('<p>').text("Analysis Error: " + value));
                        });

                    } else if (wasSuccessful) {
                        //console.log(rData[1]);


                        // show result section
                        $("#result-section").css("display", "block");

                        if (rInformation != null) {
                            // print information from R
                        }

                        // RESULT TABLE

                        // remove old rows if there are any
                        $("#result-table").find($("tbody")).empty();

                        // add rows and fill with data
                        let tr;
                        for (let i = 0; i < rData[0].length; i++) {
                            // console.log(rData[0][i]);

                            tr = $('<tr/>');
                            tr.append("<td>" + rData[0][i].signature + "</td>");
                            tr.append("<td>" + rData[0][i].rank + "</td>");
                            tr.append("<td>" + rData[0][i].perturbation + "</td>");
                            tr.append("<td>" + rData[0][i].score + "</td>");
                            tr.append("<td>" + rData[0][i].fdr + "</td>");
                            tr.append("<td>" + rData[0][i].direction + "</td>");
                            $("table#result-table").find($("tbody")).append(tr);
                        }


                        // ENRICHMENT TABLE
                        console.log(rData[0]);
                        console.log(rData[1]);

                        // remove old rows if there are any
                        $("#enrichment-table").find($("tbody")).empty();

                        // add rows and fill with data
                        for (let i = 0; i < rData[1].length; i++) {
                            //console.log(rData[1][i]);

                            tr = $('<tr class="view-plot" />');
                            tr.append("<td>" + rData[1][i].target + "</td>");
                            tr.append("<td>" + rData[1][i].dvalue + "</td>");
                            tr.append("<td>" + rData[1][i].pvalue + "</td>");
                            tr.append("<td>" + rData[1][i].direction + "</td>");
                            tr.append("<td>" + '<div class="hidden-plot"><img src="data:image/png;base64,' + rData[1][i].distribution + '" / >' + "</div></td>");
                            $("table#enrichment-table").find($("tbody")).append(tr);
                        }


                    } else {
                        // something bad happened...
                    }

                })
                .always(function() {
                    // remove loading image maybe
                    console.log("always");
                })
                .fail(function(jqXHR, textStatus) {
                    // handle request failures
                    console.log("fail");
                    console.log(textStatus);
                });

        }

    });*/


    // ==================================================== differentiation markers toggle


    $("input[name='risk-type-radio']").change(function () {

        if ($("#type-gene").is(":checked")) {

            // set al clinical variables to unchecked and hide box
            $("input[name='stratifications[]']:checked").each(function () {
                if ($(this).is(":checked")) {
                    $(this).prop('checked', false);
                }
            });
            $(".scroll-wrapper").css("display", "none");

            // remove heatmap
            $("#filter-heatmap").empty();

            // show text boxes for gene symbols
            $("#differentiation-markers-wrapper").css("display", "block");

        } else if ($("#type-clinical").is(":checked")) {

            // empty gene symbols and hide text boxes
            $("#markers-positive").val("");
            $("#markers-negative").val("");
            $("#differentiation-markers-wrapper").css("display", "none");

            // show text boxes for clinical variables
            $(".scroll-wrapper").css("display", "block");
        }

    });


    // =============================================================== cox analysis toggle

    $('#run-cox').change(function() {
        if(this.checked) {
            // show options
            $("#cox-options").css("display", "block");
        } else {
            // hide options
            $("#cox-options").css("display", "none");
        }
    });


    // ========================================================================= Modal box

    // Get the modal
    let modal = document.getElementById("modal-formatting");

    // Get the button that opens the modal
    let btn = document.getElementById("formatting-link");

    // Get the <span> element that closes the modal
    let span = document.getElementsByClassName("close")[0];

    // When the user clicks on the button, open the modal
    btn.onclick = function() {
        modal.style.display = "block";
    };

    // When the user clicks on <span> (x), close the modal
    span.onclick = function() {
        modal.style.display = "none";
    };

    // When the user clicks anywhere outside of the modal, close it
    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    };


    // ==================================================================== Bootstrap Tour

    // start tour when user goes to the analysis page
    $(document).on("click", "#analysis-button", function () {

    });

    $(document).on("click", "#start-tour", function () {
        setTimeout(function() {
            initializeTour();
        }, 2000);
    });




// ==================================================================== document ready end
});

function initializeTour() {
    let tour = new Tour({
        steps: [
            {
                element: "#start-title",
                title: "Hello and Welcome!",
                content: "I am the magnificent Target Translator Wizard, but you can call me Wiz for short. I will walk you through your first analysis, and then you can play around on your own.",
                placement: "auto bottom"
            },
            {
                element: "#preprocessed-data",
                title: "Select data",
                content: "The first step is to select the data that contains all the exiting stuff. To get you going, I have put together some pre-formatted dataset for you. Let's select the TARGET dataset for now.",
                placement: "auto left"
            },
            {
                element: "#upload-fields",
                title: "Select data",
                content: "You can also upload you own datasets. Just make sure to follow the formatting instructions in the documentation, and this will be a easy process. For now, we will skip this.",
                placement: "auto right"
            },
            {
                element: "#select-stratifications",
                title: "Risk group definitions",
                content: "What is a risk group really? Only you know. But for neuroblastoma, MYCN amplification might be an important criteria. Go ahead and select it. ",
                placement: "auto top"
            },
            {
                element: "#differentiation-markers",
                title: "Risk group definitions",
                content: "Have a list of differentiation markers? Just paste them into the correct boxes. But don't do that this time, let's keep it simple while learning...",
                placement: "auto left"
            },
            {
                element: "#run-cox",
                title: "Additional settings",
                content: "If you want to define you risk group by survival time, I would suggest the you check this checkbox. But the MYCN amplification has nothing with time to do, so just skip it for now.",
                placement: "auto left"
            },
            {
                element: "#submit-section",
                title: "Great Work!",
                content: "Read through your settings to make sure that they are correct before clicking the \"Find my targets\"-button. The analysis can take up to a few minutes, so go and grab a coffee while waiting. If you ever need me again, just click the \"Start Tour\"-button up to the right. Good luck with you research! -Wiz",
                placement: "auto top"
            }
        ],
        smartPlacement: false,
        debug: true
    });

    // Initialize the tour
    tour.init();

    // Start from the beginning
    tour.setCurrentStep(0);

    // Start the tour
    tour.start();
}