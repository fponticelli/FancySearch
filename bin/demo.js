// Generated by Haxe
(function (console) { "use strict";
var Main = function() {
	var options = { suggestions : ["Apple","Banana","Carrot","Peach","Pear","Turnip"]};
	var input = window.document.querySelector("input.fancify");
	this.search = new fancy_Search(input,options);
};
Main.main = function() {
	new Main();
};
var fancy_Search = function(el,options) {
	if(options.suggestions != null) this.suggestions = options.suggestions; else this.suggestions = [];
	if(options.filterFn != null) this.filterFn = options.filterFn; else this.filterFn = fancy_Search.defaultFilterer;
	if(options.classes != null) this.classes = options.classes; else this.classes = { };
	if(this.classes.input != null) this.classes.input = this.classes.input; else this.classes.input = "fs-search-input";
	el.classList.add(this.classes.input);
};
fancy_Search.defaultFilterer = function(suggestion,search) {
	return suggestion.indexOf(search) >= 0;
};
Main.main();
})(typeof console != "undefined" ? console : {log:function(){}});
