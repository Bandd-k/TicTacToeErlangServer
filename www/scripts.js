$(document).ready(load_data(0.0))
function load_data(value){
	var prefix = "/api/studients/scores/"+ value
	var columns = ["github_login","score_first","score_second"]
	var new_tag = $
	var find_tags = $
	var jQuery = $

	$("#table_data").empty()
	$.getJSON(prefix , function(result){
//		var row = $("<tr>")
		$.each(result,function(){
			var row = $("<tr>")
			var person = this
			$.each(columns,function(){
				var column = $("<td>").text(person[this])
				column.appendTo(row)
			})
			row.appendTo($("#table_data"))
			

		})

	})

}

