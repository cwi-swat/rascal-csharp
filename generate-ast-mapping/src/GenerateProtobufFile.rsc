module GenerateProtobufFile

import CSharpNRefactory;
import List;
import CSharp;

public str generateProtobuf(list[Ast] info) {
	str result = "package Landman.Rascal.CSharp.Profobuf;\n\noption optimize_for = SPEED;\n";
	for (mes <- info, enumConstant(_,_) !:= last(head(mes.alt).underlying.id)) {
		result += "message <mes.name> { \n";
		int kindCounter = 0;
		result += "  enum <mes.name>Kind { \n";
		for (a <- mes.alt) {
			result += "    <a.name> = <kindCounter>;\n";
			kindCounter += 1;
		} 
		result += "  }\n";
		result += "  required <mes.name>Kind Kind = 1;\n";
		props = {<p.name, p.\type, p> | p <- {toSet(a.props) | a <- mes.alt}};
		int fieldCounter = 2;
		for (p <- props) {
			if (single(_,_,_) := p[2]) 
				result += "  optional ";
			else 
				result += "  repeated ";
			result += "<translateType(p[1])> <p[0]> = <fieldCounter>;\n";
			fieldCounter += 1;
		}
		result += "} \n";
	}
	for (mes <- info, enumConstant(_,_) := last(head(mes.alt).underlying.id)) {
		result += "enum <mes.name> { \n";
		int enumCounter = 0;
		for (a <- mes.alt) {
			result += "    <a.name> = <enumCounter>;\n";
			enumCounter += 1;
		} 
		result += "}\n";
	}
	
	return result;
}

str translateType(str rscType) {
	switch(rscType) {
		case "str" : return "string";
		case "int" : return "int32";
		case "bool" : return "bool";
		default : return rscType;
	}	
}
