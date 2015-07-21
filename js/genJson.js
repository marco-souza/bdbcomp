// Requirements
var mysql = require('mysql')
var fs = require('fs')

// Connect to Database
var conData = {
	host		: '172.17.0.1',
	user		: 'root',
	password: 'root',
	database: 'bdbcomp'
}
var con = mysql.createConnection(conData);

con.connect()

// Make query
var query = 'SELECT c.creator as name,count(wc.id_work) as Quantidade FROM creator c, work_creator wc WHERE c.id_creator = wc.id_creator GROUP BY c.creator ORDER BY count(wc.id_work) DESC LIMIT 0,10';

con.query(query, function(er, rows, fields) {
	if (er) console.error(er);

	// Save json file
	fs.writeFile('data.json',JSON.stringify(rows), function(e){
		if (e) console.error("File not generated:",e);
		else console.log("Generated data.json");
	});
})

con.end()
