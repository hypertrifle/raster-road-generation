var util = require('util');
var fs = require('fs');
var log_file = fs.createWriteStream(__dirname + '/../logs/pre-hook.log', {flags : 'w'});
var log_stdout = process.stdout;
var exec = require('child_process').exec;

console.log = function(d) { //
  log_file.write(util.format(d) + '\n');
  //log_stdout.write(util.format(d) + '\n'); //for when debugging scripts (outputs with flow --log 3).
};

function save(error, stdout, stderr) { console.log(stdout) }


exports.hook = function(flow, done) {
	exec('hooks/pre-hook.sh', save);



	done();
}



