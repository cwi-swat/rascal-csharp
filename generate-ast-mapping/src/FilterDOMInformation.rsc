module FilterDOMInformation

import CLRInfo;
import CSharp;
import dotNet;

import List;
import Map;
import IO;
import Set;
import Graph;
import Relation;
import String;

public Entity astNode = entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), class("AstNode")]);

public map[Entity, rel[str,Entity]] CollectTypesAndProperties(Resource nrefactory)
{
	set[Entity] astTypes = {t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types};
	EntityRel flattedExtends = (nrefactory@extends)*;
	set[Entity] astClasses = {t | <t, astNode> <- flattedExtends, !startsWith(last(t.id).name,"Null")};
	flattedExtends = {r | r <- flattedExtends, <_,Object> !:= r, r[0] in astClasses};
	set[Entity] nonAbstractClasses = {c | c <- astClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})};
	rel[Entity, Id] astProperties = {<entity(ids),p> | /entity([ids*,p:property(_,_,_,_)]) <- nrefactory@properties, p.name != "IsNull", /class("CSharpTokenNode") !:= p.propertyType, /entity(ids) := astClasses};
	return (c : {<p.name, p.propertyType> | p <- astProperties[flattedExtends[c] - {astNode}]} | c <- nonAbstractClasses);
}


public void GenerateRascalDataFile() {
	Resource nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
	map[Entity, rel[str,Entity]] props = CollectTypesAndProperties(nrefactory);
	// all classes extending astNode are the root of the AST
	
	println("data AstNode = ");
	bool first = true;
	for (e <- props, <e, astNode> in (nrefactory@extends) || hasOnlyNonAbstractSuperClasses(nrefactory, e)) {
		// now we have the classes ready to form the head of the AST
		println("  <first? "" : "|"> <generateAlternativeFormName(e)>(<generateParams(props[e])>)");
		first = false;
	}
	// now let's add all the types which are abstract wrappers for actual types
	EntityRel extending = invert(nrefactory@extends);
	set[Entity] astNodeAbstractImplementers = {c | c <- extending[astNode], isAbstract(nrefactory, c)};
	EntityRel extendingAll = extending*;
	for (i <- astNodeAbstractImplementers) {
		println("  | <generateAlternativeFormName(i)>(<generateDataName(i)> node)");
	}
	println(";");
	for (i <- astNodeAbstractImplementers) {
		println("data <generateDataName(i)> = ");
		first = true;
		for (p <- extendingAll[i], p in props) {
			println("  <first? "" : "|"> <generateAlternativeFormName(p)>(<generateParams(props[p])>)");
			first = false;
		}
		println(";");
	}
	set[Entity] extraProperties = {range(r) | r <- range(props)};
	extraProperties = {p | p:entity([_*,class(_)]) <- extraProperties}
		+ {p | p:entity([_*,enum(_,_)]) <- extraProperties}
		+ {head(i.params) | entity([_*,i:interface("IEnumerable",_)]) <- extraProperties}
		- astNodeAbstractImplementers - {astNode};
	for (p <- extraProperties, /class("Boolean") !:= p, /class("String") !:= p, /class("Int32") !:= p, p != Object) {
		println("data <generateDataName(p)> = ");
		first = true;
		if (class(_) := last(p.id)) {
			for (p <- extendingAll[p], p in props) {
				println("  <first? "" : "|"> <generateAlternativeFormName(p)>(<generateParams(props[p])>)");
				first = false;
			}
		}
		else {
			for (ei <- last(p.id).items) {
				println("  <first? "" : "|"> <generateAlternativeFormName(ei)>()");
				first = false;
			}
		}
		println(";");
	}
	
}
private bool hasOnlyNonAbstractSuperClasses(Resource nrefactory, Entity dst) {
	if (dst == astNode)
		return true;
	return (!isAbstract(nrefactory, dst)) 
		&& hasOnlyNonAbstractSuperClasses(nrefactory, getOneFrom((nrefactory@extends)[dst]));
}

private bool isAbstract(Resource nrefactory, Entity dst) {
	return !isEmpty((nrefactory@modifiers)[dst] & {abstract()});
}
private str generateAlternativeFormName(Entity ent) {
	return camelCase(last(ent.id).name);
}

private str generateDataName(Entity ent) {
	Id cl = last(ent.id);
	if (cl.name == "IEnumerable") {
		return "list[<generateDataName(head(cl.params))>]";
	}
	else if (cl.name == "String") {
		return "str";
	}
	else if (cl.name == "Int32") {
		return "int";
	}
	else if (cl.name == "Boolean") {
		return "bool";
	}
	else {
		return cl.name;
	}
}

private str generateParams(rel[str,Entity] params) {
	str result = "";
	bool first = true;
	for (p <- params, /class("AstLocation") !:= p[1]) {
		result += (first ? "" : ", ") + generateDataName(p[1]) + " " + camelCase(p[0]);
		first = false;
	}
	return result;
}


private str camelCase(str input) {
	int length = size(input);
	return toLowerCase(substring(input, 0, 1)) + substring(input, 1, length); 
}
