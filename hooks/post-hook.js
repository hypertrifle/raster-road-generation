var util = require('util');
var fs = require('fs');
var log_file = fs.createWriteStream(__dirname + '/../logs/post-hook.log', {flags : 'w'});
var log_stdout = process.stdout;
var exec = require('child_process').exec;

console.log = function(d) { //
  log_file.write(util.format(d) + '\n');
  //log_stdout.write(util.format(d) + '\n');
};

function save(error, stdout, stderr) { console.log(stdout) }


exports.hook = function(flow, done) {
	exec('hooks/post-hook.sh', save);



	done();
}



