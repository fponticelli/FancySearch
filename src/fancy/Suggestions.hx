package fancy;

import js.html.Element;
import haxe.ds.StringMap;
using thx.Arrays;
using thx.Functions;
using thx.Iterators;
using fancy.util.Dom;
using thx.Tuple;

typedef FilterFunction = Array<String> -> String -> Array<String>;
typedef HighlightLetters = Array<String> -> String -> Array<Tuple2<Int, Int>>;
typedef SelectionChooseFunction = String -> Void;

typedef SuggestionBoxClassNames = {
  suggestionContainer : String,
  suggestionsOpen : String,
  suggestionsClosed : String,
  suggestionList : String,
  suggestionsEmpty : String,
  suggestionItem : String,
  suggestionItemSelected : String,
};

typedef SuggestionOptions = {
  classes : SuggestionBoxClassNames,
  ?filterFn : FilterFunction,
  ?highlightLettersFn : HighlightLetters,
  limit : Int,
  onChooseSelection : SelectionChooseFunction,
  parent : Element,
  ?suggestions : Array<String>,
};

class Suggestions {
  public var parent(default, null) : Element;
  public var classes(default, null) : SuggestionBoxClassNames;
  public var limit(default, null) : Int;
  public var onChooseSelection(default, null) : SelectionChooseFunction;
  public var suggestions(default, null) : Array<String>;
  public var filtered(default, null) : Array<String>;
  public var elements(default, null) : StringMap<Element>;
  public var selected(default, null) : String; // selected item in `filtered`
  public var filterFn : FilterFunction;
  public var highlightLettersFn : HighlightLetters;
  public var isOpen : Bool;
  var el : Element;
  var list : Element;

  public function new(options : SuggestionOptions) {
    // defaults
    parent = options.parent;
    classes = options.classes;
    limit = options.limit;
    onChooseSelection = options.onChooseSelection;
    suggestions = options.suggestions != null ? options.suggestions : [];
    filtered = suggestions.copy();
    selected = '';
    filterFn = options.filterFn != null ? options.filterFn : defaultFilterer;
    highlightLettersFn = options.highlightLettersFn != null ?
      options.highlightLettersFn :
      defaultHighlightLetters;
    isOpen = false;
    elements = suggestions.reduce(function (acc : StringMap<Element>, curr) {
      acc.set(curr, Dom.create('li.${classes.suggestionItem}', curr));
      return acc;
    }, new StringMap<Element>());

    // set up the dom
    elements.keys().map(function (elName) {
      elements.get(elName)
        .on('mouseover', function (_) {
          selectItem(elName);
        })
        .on('mousedown', function (_) {
          chooseSelectedItem();
        })
        .on('mouseout', function (_) {
          selectItem(); // select none
        });
    });

    list = Dom.create(
      'ul.${classes.suggestionList}',
      [for (item in elements) item]
    );
    el = Dom.create('div.${classes.suggestionContainer}.${classes.suggestionsClosed}', [list]);

    parent.appendChild(el);
  }

  public function filter(search : String) {
    search = search.toLowerCase();
    filtered = filterFn(suggestions, search).slice(0, limit);
    var wordParts = highlightLettersFn(filtered, search);

    filtered.reducei(function (list, str, index) {
      var el = elements.get(str).empty(),
          wordRange = wordParts[index];

      // if the highlighted range isn't at the beginning, span it
      if (wordRange.left != 0)
        el.appendChild(Dom.create('span', str.substr(0, wordRange.left)));

      // if the range to highlight has a non-zero length, strong it
      if (wordRange.right > 0)
        el.appendChild(Dom.create('strong', str.substr(wordRange.left, wordRange.right)));

      // if the range didn't end at the end of the string, span the rest
      if (wordRange.left + wordRange.right < str.length)
        el.appendChild(Dom.create('span', str.substr(wordRange.right + wordRange.left)));

      list.appendChild(el);
      return list;
    }, list.empty());

    if (!filtered.contains(selected)) {
      selected = "";
    }

    if (filtered.length == 0) {
      el.addClass(classes.suggestionsEmpty);
    } else {
      el.removeClass(classes.suggestionsEmpty);
    }
  }

  public function open() {
    isOpen = true;
    el.removeClass(classes.suggestionsClosed)
      .addClass(classes.suggestionsOpen);
  }

  public function close() {
    isOpen = false;
    selectItem();
    el.removeClass(classes.suggestionsOpen)
      .addClass(classes.suggestionsClosed);
  }

  public function selectItem(?key : String = '') {
    if (selected != '') {
      elements.get(selected).removeClass(classes.suggestionItemSelected);
    }

    selected = key;
    if (elements.get(selected) != null)
      elements.get(selected).addClass(classes.suggestionItemSelected);
  }

  public function moveSelectionUp() {
    var currentIndex = filtered.indexOf(selected),
      targetIndex = currentIndex > 0 ? currentIndex - 1 : filtered.length - 1;

    selectItem(filtered[targetIndex]);
  }

  public function moveSelectionDown() {
    var currentIndex = filtered.indexOf(selected),
      targetIndex = (currentIndex + 1) == filtered.length ? 0 : currentIndex + 1;

    selectItem(filtered[targetIndex]);
  }

  public function chooseSelectedItem() {
    onChooseSelection(selected);
  }

  static function defaultFilterer(suggestions : Array<String>, search : String) {
    search = search.toLowerCase();
    return suggestions
      .filter.fn(_.toLowerCase().indexOf(search) >= 0)
      .order(function (a, b) {
        var posA = a.toLowerCase().indexOf(search),
            posB = b.toLowerCase().indexOf(search);

        return if (posA == posB)
          if (a < b) -1 else if ( a > b ) 1 else 0;
        else
          posA - posB;
      });
  }

  static function defaultHighlightLetters(filtered : Array<String>, search :String) {
    return filtered.map.fn(new Tuple2(_.toLowerCase().indexOf(search), search.length));
  }
}
