var newman = require('newman'); 
// require newman in your project

// call newman.run to pass `options` object and wait for callback
newman.run({
    collection: require('./collections/SODA_API_E2E_Tests.postman_collection.json'),
    globals: require('./env/SODA_Globals.postman_globals.json'),
    environment: require('./env/SODA_API.postman_environment.json'),
    reporters: ['htmlextra','cli'],
    //bail: true,
    reporter: {
        htmlextra: {
            export: './e2e_reports/soda_api_e2e_report.html',
            // template: './template.hbs'
            logs: true,
            // showOnlyFails: true,
            // noSyntaxHighlighting: true,
            // testPaging: true,
            browserTitle: "SODA API E2E Test report",
            title: "SODA API E2E Test report",
            titleSize: 4,
            // omitHeaders: true,
            //skipHeaders: "X-Auth-Token",
           // hideRequestBody: ["Register Backend", "Register Backend Invalid Credentials"],
            //hideResponseBody: ["Register Backend", "Register Backend Invalid Credentials"],
            // showEnvironmentData: true,
            // skipEnvironmentVars: ["API_KEY"],
            // showGlobalData: true,
            //skipGlobalVars: ["authToken"],
            // skipSensitiveData: true,
            // showMarkdownLinks: true,
            // showFolderDescription: true,
            // timezone: "Australia/Sydney"
        }
    },
    insecure: true, // allow self-signed certs, required in postman too,
    delayRequest: 2500,
    //timeout: 180000  // set time out,
}).on('start', function (err, args) { // on start of run, log to console
    console.log('Running E2E tests for SODA API ...');
}).on('done', function (err, summary) {
    if (err || summary.error) {
        console.error('collection run encountered an error.', err);
        console.log("Summary Error",summary.error);
    }
    else {
        console.log('collection run completed.');
    }
});