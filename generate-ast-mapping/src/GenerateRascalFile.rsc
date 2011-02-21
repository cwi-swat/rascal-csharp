module GenerateRascalFile

import CSharpNRefactory;
import List;

public str GenerateFor(list[Ast] info) {
	str result = "module CSharp\n\npublic alias CSharpFile=list[Ast];\n";
	for (h <- info) {
		result += "data <h.name> = ";
		bool first = true;
		for (a <- h.alt) {
			result += "<first ? "" : "\n  |  "><a.name>(";
			bool firstProp = true;
			for (p <- a.props) {
				result += firstProp ? "" : ", ";
				if (single(_,_,_) := p) {
					result += "<p.\type> <p.name>";
				} 
				else {
					result += "list[<p.\type>] <p.name>";
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