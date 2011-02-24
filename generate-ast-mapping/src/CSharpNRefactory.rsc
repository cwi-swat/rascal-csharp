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
	EntitySet mainPublicAstClasses = {c | c <- extending[astNode], c in astClasses, !(abstract() in (nrefactory@modifiers)[c])};
	mainPublicAstClasses +=  {(extending+)[c] | c <- mainPublicAstClasses, !(abstract() in (nrefactory@modifiers)[(extending+)[c]])};
	PropertyRel properties = getPropertiesFor(astClasses, nrefactory);
	EntitySet relatedTypes = {isCollection(p.propertyType) ? head(getLastId(p.propertyType).params) : p.propertyType
		| p <- range(properties), !(p.propertyType in astClasses), !isPrimitive(p.propertyType)}
		- mainPublicAstClasses;
	PropertyRel relatedProperties = getPropertiesFor(relatedTypes, nrefactory);
	
	EntityRel allSuperClasses = (nrefactory@extends)+;
	EntitySet ignorePropertiesFrom = {astNode, Object};
	list[Ast] result = [\data("AstNode", 
		[alternative(getAlternativeName(getLastId(c).name), generatePropertyList(c, properties, allSuperClasses, ignorePropertiesFrom), c)
			| c <- mainPublicAstClasses]
		+ // add the basic abstract classes
		[alternative(getAlternativeName(getLastId(c).name), [single("node", getDataName(c), property("this", c, entity([]), entity([])))], c) 
			| c <- extending[astNode], abstract() in (nrefactory@modifiers)[c]]
		)];
	EntitySet relatedTypesLeft = (relatedTypes + {c | c<- extending[astNode], abstract() in (nrefactory@modifiers)} - ignorePropertiesFrom);
	do 
	{
		Entity td = getOneFrom(relatedTypesLeft);
		relatedTypesLeft -= {td};
		result += [\data(getDataName(last(td.id).name), (enum(_,_,_) := last(td.id)) ?
				[alternative(getAlternativeName(getLastId(e).name), [], e) 
					| e <- last(td.id).items]
				: [alternative(getAlternativeName(getLastId(t).name) 
					, generatePropertyList(t, properties, allSuperClasses, ignorePropertiesFrom)
					, t)
					| t <- (extending[td] + {t2 | t2 <- (extending+)[td], !(abstract() in (nrefactory@modifiers)[allSuperClasses[t2]-allSuperClasses[td] - {td}])}), !(abstract() in (nrefactory@modifiers)[t]) ]
				+ [alternative(getAlternativeName(getLastId(t).name), [single("node", getDataName(t), property("this", t, entity([]), entity([])))], t)
					| t <- extending[td], (abstract() in (nrefactory@modifiers)[t]) ])];
		relatedTypesLeft += {t | t <- extending[td], (abstract() in (nrefactory@modifiers)[t])};
	} while (!isEmpty(relatedTypesLeft)); 
	
	return result;
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
		currentProps -= [head(p)];	
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


private str camelCase(str input) {
	int length = size(input);
	return toLowerCase(substring(input, 0, 1)) + substring(input, 1, length); 
}
