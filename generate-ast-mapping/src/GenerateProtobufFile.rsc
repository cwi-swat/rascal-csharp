module GenerateProtobufFile

import CSharpNRefactory;
import List;
import CSharp;

public str generateProtobuf(list[Ast] info, bool csharpVersion) {
	str result = "package Landman.Rascal.CSharp.Profobuf;\n\noption optimize_for = SPEED;\n";
	if (csharpVersion) {
		result += "import \"google/protobuf/csharp_options.proto\";\n";
		result += "option (google.protobuf.csharp_file_options).namespace = \"Landman.Rascal.CSharp.Profobuf\";\n";
		result += "option (google.protobuf.csharp_file_options).umbrella_classname = \"CSharoASTProtos\";\n";
	}
	result += "message CSharpParseRequest { \n" +
		"  required string Filename = 1;\n" +
		"}\n" +
		"message CSharpParseResult {\n" +
		"  repeated AstNode Result = 1 \n;" +
		"}\n";
	for (mes <- info, enumConstant(_,_) !:= last(head(mes.alt).underlying.id)) {
		result += "message <mes.name> { \n";
		int kindCounter = 0;
		result += "  enum <mes.name>Kind { \n";
		for (a <- mes.alt) {
			result += "    k_<a.name> = <kindCounter>;\n";
			kindCounter += 1;
		} 
		result += "  }\n";
		result += "  required <mes.name>Kind Kind = 1;\n";
		props = {<p.name, p.\type, single(_,_,_) := p> | p <- {toSet(a.props) | a <- mes.alt}};
		int fieldCounter = 2;
		for (p <- props) {
			if (p[2]) 
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
		case "value": return "string"; // we cannot map value to something in Protobuf, so java will have to try to parse the string back to a primitive
		default : return rscType;
	}	
}
