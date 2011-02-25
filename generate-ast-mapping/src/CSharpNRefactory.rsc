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
	EntitySet mainPublicAstClasses = {c | c <- extending[astNode], c in astClasses, !(abstract() in (nrefactory@modifiers)[c]), !startsWith(last(c.id).name,"Null")};
	mainPublicAstClasses +=  {(extending+)[c] | c <- mainPublicAstClasses, !(abstract() in (nrefactory@modifiers)[(extending+)[c]])};
	mainPublicAstClasses -= {c | c <- mainPublicAstClasses, startsWith(last(c.id).name,"Null")}; // Remove null object pattern classes
	PropertyRel properties = getPropertiesFor(astClasses, nrefactory);
	EntitySet relatedTypes = {isCollection(p.propertyType) ? head(getLastId(p.propertyType).params) : p.propertyType
		| p <- range(properties), !(p.propertyType in astClasses), !isPrimitive(p.propertyType), !startsWith(last(p.propertyType.id).name,"Null") }
		- mainPublicAstClasses - {Object};
	properties += getPropertiesFor((extending+)[relatedTypes], nrefactory);
	
	EntityRel allSuperClasses = (nrefactory@extends)+;
	EntitySet ignorePropertiesFrom = {astNode, Object};

	list[Ast] result = [];
	list[Entity] relatedTypesLeft = [astNode] + toList(relatedTypes); // + {c | c<- extending[astNode], abstract() in (nrefactory@modifiers)} - ignorePropertiesFrom);
	set[str] enumAlternativesUsed = {};
	do 
	{
		Entity td = head(relatedTypesLeft);
		//println("r: <td>");
		relatedTypesLeft -= [td];
		list[Alternative] alts = [];
		if (enum(_,_,_) := last(td.id)) {
			str enumPrefix = substring(getDataName(td, nrefactory),0,1);
			rel[Entity, str] names = {<e,  getAlternativeName(getLastId(e).name)> | e <- last(td.id).items };
			alts = [alternative(((e[1] in enumAlternativesUsed) ? enumPrefix + "_" : "") + e[1], [], e[0]) 
					| e <- names];
			enumAlternativesUsed += range(names);
		} else {
			rel[str, Id] propertiesUsed = {};
			for (t <- getNonAbstractImplementors(nrefactory, extending, allSuperClasses, td), !(abstract() in (nrefactory@modifiers)[t]), !startsWith(last(t.id).name,"Null")) {
				// we need a loop for extra logic for duplicate property names without matching elements
				alts += [alternative(getAlternativeName(getLastId(t).name) , 
					generatePropertyList(t, nrefactory, properties, propertiesUsed, allSuperClasses, ignorePropertiesFrom), t)];
				propertiesUsed += {<p.name, p.underlying> | p <- last(alts).props};
			}
			// now lets add the abstract child Implementors
			set[Entity] abstractImplementors = {t | t <- extending[td], (abstract() in (nrefactory@modifiers)[t]), !/namespace("PatternMatching") := t, !(t in ignorePropertiesFrom)};
			alts += [alternative(getAlternativeName(getLastId(t).name), [single("node" + getDataName(t, nrefactory), getDataName(t, nrefactory), property("this", t, entity([]), entity([])))], t)
					| t <- abstractImplementors];
			relatedTypesLeft = toList(abstractImplementors) + relatedTypesLeft;
		}
		result += [\data(getDataName(td, nrefactory), alts)];
		
	} while (!isEmpty(relatedTypesLeft)); 
	
	return result;
}

set[Entity] getNonAbstractImplementors(Resource nrefactory, EntityRel extending, EntityRel superClasses, Entity currentClass) {
	return {t | t <- (extending+)[currentClass], 
		!(abstract() in (nrefactory@modifiers)[superClasses[t]-superClasses[currentClass] - {currentClass}])};
}

bool isCollection(Entity tp) {
	str name = getLastId(tp).name;
	return (name == "IEnumerable") || (name == "Collection") || (name == "ICollection") || (name == "AstNodeCollection"); 
}
Id getLastId(Entity src) {
	return last(src.id);
}

bool comparePropIds(Id a, Id b) {
	return a.name <= b.name;
}

list[Property] generatePropertyList(Entity c, Resource nrefactory, PropertyRel props, rel[str, Id] propsUsed, EntityRel super, EntitySet ignore) {
	list[Id] currentProps = sort(toList(props[c + super[c] - ignore]), comparePropIds);
	list[Property] result =[];
	// remove duplicate properties
	int i = 1;
	while( i < size(currentProps)) {
		if (currentProps[i-1].name == currentProps[i].name) {
			currentProps = delete(currentProps, i); 
		}
		else if (currentProps[i].name == "Name") {
			result += [single("name", "str", currentProps[i])];
			currentProps = delete(currentProps, i);
		}
		else {
			i += 1;
		}
	} 
	result += [isCollection(p.propertyType) 
		? \list(getPropertyName(p.name), getDataName(head(getLastId(p.propertyType).params), nrefactory) , p)
		:  ((enum(_,_, true) := getLastId(p.propertyType)) 
			? \list(getPropertyName(p.name), getDataName(p.propertyType, nrefactory), p)
			: single(getPropertyName(p.name), getDataName(p.propertyType, nrefactory), p))
		| p <- currentProps];
	return [ (isEmpty(propsUsed[p.name]) ? p : ((getOneFrom(propsUsed[p.name]).propertyType == p.underlying.propertyType) ? p : 
		((\list(_,_,_) := p) 
			? \list(p.name + substring(p.\type, 0, 1), p.\type, p.underlying) 
			: single(p.name + substring(p.\type, 0, 1), p.\type, p.underlying))))  | p <- result]; 	
}


str getDataName(Entity ent, Resource nrefactory) {
	switch (getLastId(ent).name) {
		case "String" : return "str";
		case "Int32" : return "int";
		case "Boolean" : return "bool";
		default: ;
	}
	if (abstract() in (nrefactory@modifiers)[ent] || (enum(_,_,_) := getLastId(ent))) {
		return escapeKeywords(getLastId(ent).name);
	}
	if (ent == astNode) {
		return "AstNode";
	}
	if (ent == Object) {
		return "value";
	}
	// it looks like we have an relation to an alternative, 
	// sadly rascal does not support this yet, so we'll 
	// have to recover the abstract class used as Data
	return getDataName(getOneFrom((nrefactory@extends)[ent]), nrefactory);
}

str getAlternativeName(Entity ent) {
	return getAlternativeName(last(ent.id).name);
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
	if (prop.name == "IsNull") return false;
	if (array(_) := head(prop.propertyType.id)) return true;
	switch (last(prop.propertyType.id).name) {
		case "AstType": return false;
		case "NodeType": return false;
		case "AstLocation": return false;
		case "CSharpTokenNode": return false;
		default: return true;
	}
}


private str camelCase(str input) {
	int length = size(input);
	return toLowerCase(substring(input, 0, 1)) + substring(input, 1, length); 
}
