module GenerateRascalFile

import CSharpNRefactory;
import List;

public str GenerateFor(list[Ast] info) {
	str result = "module CSharp\n\npublic alias CSharpFile=list[Ast];\n";
	for (h <- info) {
		result += "data <h.name> = ";
		bool first = true;
		for (a <- h.alt) {
			result += "<first ? "" : "\n  |  "><escapeKeyWord(a.name)>(";
			bool firstProp = true;
			for (p <- a.props) {
				result += firstProp ? "" : ", ";
				if (single(_,_,_) := p) {
					result += "<p.\type> <escapeKeyWord(p.name)>";
				} 
				else {
					result += "list[<p.\type>] <escapeKeyWord(p.name)>";
				} 
				firstProp = false;
			}
			result += ")";
			first = false;
		}
		result += ";\n\n";
	}
	return result;
}

str escapeKeyWord(str possible) {
	switch (possible) {
		case "module" : return "\\module";
		case "alias" : return "\\alias";
		case "value" : return "\\value";
		case "any" : return "\\any";
		case "private" : return "\\private";
		case "public" : return "\\public";
		case "true" : return "\\true";
		case "false" : return "\\false";
		case "return" : return "\\return";
		default : return possible;
	}
}