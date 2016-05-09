var fs = require('fs');
var util = require('util');
var log_file = fs.createWriteStream(__dirname + '/../logs/last-build-haxelib.log', {flags : 'w'});
var log_stdout = process.stdout;
var exec = require('child_process').exec;

console.log = function(d) { //
  log_file.write(util.format(d) + '\n');
  //log_stdout.write(util.format(d) + '\n');
};

function save(error, stdout, stderr) { console.log(stdout) }


exports.hook = function(flow, done) {
	exec("haxelib list", save);
	console.log(flow.flags);
	console.log(flow.target);
	done();
	}



