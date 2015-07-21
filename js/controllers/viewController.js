app.controller("viewController", ['$scope', function($scope) {

	$scope.selected = 0;

	$scope.allViews = [
		{
			name: "Simple Tree Map",
			description: "Tree Chart with the 10 people who has more work	published.",
			genView: function() {
				
				var viz = {};
				d3.json('js/data.json', function(er, data) {
					if (er) console.error(er);

					// Generate View
					viz =
					d3plus.viz().container("#selected-view").data(data).type("tree_map").id("name").size("Quantidade").draw();
				});
			}
		},
		{
			name: "Simple Pie Chart",
			description: "Pie Chart with the 10 people who has more work published.",
			genView: function() {
				
				d3.json('js/data.json', function(er, data) {
					if (er) console.error(er);

					// Generate View
					viz =
					d3plus.viz().container("#selected-view").data(data).type("pie").id("name").size("Quantidade").draw();
				});
			}
		},
		{
			name: "view 3"
		},
		{
			name: "view 4"
		},
		{
			name: "view 5"
		}
	]

	$scope.chooseView = function(index) {

		$scope.selected = index;
		$scope.allViews[index].genView();

	}

	$scope.chooseView(0)

}]);
