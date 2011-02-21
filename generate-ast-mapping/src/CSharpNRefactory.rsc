module CSharpNRefactory

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

data Ast = \data(str name, list[Alternative] alt);
data Alternative = alternative(str name, list[Property] props, Entity underlying);
data Property = single(str name, str \type, Id underlying)
	| \list(str name, str \type, Id underlying);


// nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
public list[Ast] generateStructureFor(Resource nrefactory) {
	EntityRel extending = invert(nrefactory@extends);
	EntitySet astClasses = (extending+)[astNode];
	astClasses -= {c | c <- astClasses, startsWith(last(c.id).name,"Null")}; // Remove null object pattern classes
	PropertyRel properties = getPropertiesFor(astClasses, nrefactory);
	EntitySet relatedTypes = {isCollection(p.propertyType) ? head(getLastId(p.propertyType).params) : p.propertyType
		| p <- range(properties), !(p.propertyType in astClasses), !isPrimitive(p.propertyType)};
	PropertyRel relatedProperties = getPropertiesFor(relatedTypes, nrefactory);
	
	
	EntityRel allSuperClasses = (nrefactory@extends)+;
	EntitySet ignorePropertiesFrom = {astNode, Object};
	list[Ast] result = [\data("AstNode", 
		[alternative(getAlternativeName(getLastId(c).name), generatePropertyList(c, properties, allSuperClasses, ignorePropertiesFrom), c)
			| c <- extending[astNode], c in astClasses, !(abstract() in (nrefactory@modifiers)[c])]
		+ // add the basic abstract classes
		[alternative(getAlternativeName(getLastId(c).name), [single("node", getDataName(c), property("this", c, entity([]), entity([])))], c) 
			| c <- extending[astNode], abstract() in (nrefactory@modifiers)[c]]
		)];
	return result += [\data(getDataName(last(td.id).name),
		(enum(_,_,_) := last(td.id)) ?
			[alternative(getAlternativeName(getLastId(e).name), [], e) 
				| e <- last(td.id).items]
			: [alternative(getAlternativeName(getLastId(t).name) 
				, generatePropertyList(t, properties, allSuperClasses, ignorePropertiesFrom)
				, t)
				| t <- extending[td]])
		|  td <- (relatedTypes + {c | c<- extending[astNode], abstract() in (nrefactory@modifiers)} - ignorePropertiesFrom)];
}
bool isCollection(Entity tp) {
	str name = getLastId(tp).name;
	return (name == "IEnumerable") || (name == "Collection"); 
}
Id getLastId(Entity src) {
	return last(src.id);
}

bool comparePropIds(Id a, Id b) {
	return a.name <= b.name;
}

list[Property] generatePropertyList(Entity c, PropertyRel props, EntityRel super, EntitySet ignore) {
	list[Id] currentProps = sort(toList(props[c + super[c] - ignore]), comparePropIds);
	list[Property] result =[];
	if (p:/property("Name",_,_,_) := currentProps) {
		currentProps -= [p];	
		result += [single("name", "str", head(p))];
	}
	return result + [isCollection(p.propertyType) 
		? \list(getPropertyName(p.name), getDataName(head(getLastId(p.propertyType).params)) , p)
		:  ((enum(_,_, true) := getLastId(p.propertyType)) 
			? \list(getPropertyName(p.name), getDataName(getLastId(p.propertyType)), p)
			: single(getPropertyName(p.name), getDataName(getLastId(p.propertyType)), p))
		| p <- currentProps];	
}


str getDataName(Entity ent) {
	return getDataName(getLastId(ent));
}
str getDataName(Id id) {
	return getDataName(id.name);
}
str getDataName(str name) {
	switch (name) {
		case "String" : return "str";
		case "Int32" : return "int";
		case "Boolean" : return "bool";
		default: return escapeKeywords(name);
	}
}

str getAlternativeName(str name) {
	return escapeKeywords(camelCase(name));
}

str getPropertyName(str name) {
	return escapeKeywords(camelCase(name));
}

str escapeKeywords(str possibleKeyword) {
	return possibleKeyword;
}

bool isPrimitive(Entity tp) {
	switch (last(tp.id).name) {
		case "String" : return true;
		case "Int32" : return true;
		case "Boolean" : return true;
		default: return false;
	}
}
alias PropertyRel = rel[Entity class, Id property];

PropertyRel getPropertiesFor(set[Entity] classes, Resource nrefactory) {
	return {<entity(c), p> | e:entity([c*, p]) <- nrefactory@properties, 
			entity(c) in classes, isValidPropertyFor(p)};
}

bool isValidPropertyFor(Id prop){
	return prop.name != "IsNull" && last(prop.propertyType.id).name != "CSharpTokenNode" && last(prop.propertyType.id).name != "NodeType" ;
}

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
