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

import vis::Figure;
import vis::Render; 

public Entity domNode = entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), class("DomNode")]);

//  nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
public map[Entity, rel[str,Entity]] CollectTypesAndProperties(Resource nrefactory)
{
	set[Entity] domTypes = {t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types};
	//Entity domNode = head([e | e:entity([_*,class("DomNode")]) <- domTypes]);
	EntityRel flattedExtends = (nrefactory@extends)*;
	set[Entity] domClasses = {t | <t, domNode> <- flattedExtends, !startsWith(last(t.id).name,"Null")};
	flattedExtends = {r | r <- flattedExtends, <_,Object> !:= r, r[0] in domClasses};
	set[Entity] nonAbstractClasses = {c | c <- domClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})};
	rel[Entity, Id] domProperties = {<entity(ids),p> | /entity([ids*,p:property(_,_,_,_)]) <- nrefactory@properties, /entity(ids) := domClasses};
	return (c : {<p.name, p.propertyType> | p <- domProperties[flattedExtends[c]]} | c <- nonAbstractClasses);
}


public void GenerateRascalDataFile() {
	Resource nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
	map[Entity, rel[str,Entity]] props = CollectTypesAndProperties(nrefactory);
	// all classes extending DomNode are the root of the AST
	
	println("data DomNode = ");
	bool first = true;
	for (e <- props, <e, domNode> in (nrefactory@extends) || hasOnlyNonAbstractSuperClasses(nrefactory, e)) {
		// now we have the classes ready to form the head of the AST
		println("  <first? "" : "|"> <generateAlternativeFormName(e)>()");
		first = false;
	}
	// now let's add all the types which are abstract wrappers for actual types
	EntityRel extending = invert(nrefactory@extends);
	set[Entity] domNodeAbstractImplementers = {c | c <- extending[domNode], isAbstract(nrefactory, c)};
	EntityRel extendingAll = extending*;
	for (i <- domNodeAbstractImplementers) {
		println("  | <generateAlternativeFormName(i)>(<generateDataName(i)> node)");
	}
	println(";");
	for (i <- domNodeAbstractImplementers) {
		println("data <generateDataName(i)> = ");
		first = true;
		for (p <- extendingAll[i], p in props) {
			println("  <first? "" : "|"> <generateAlternativeFormName(p)>()");
			first = false;
		}
		println(";");
	}
}
private bool hasOnlyNonAbstractSuperClasses(Resource nrefactory, Entity dst) {
	if (dst == domNode)
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
	return last(ent.id).name;
}


private str camelCase(str input) {
	int length = size(input);
	return toLowerCase(substring(input, 0, 1)) + substring(input, 1, length); 
}

public void PrintResults() {
	Resource nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
	map[Entity, set[tuple[str,Entity]]] entityWithProperties = CollectTypesAndProperties(nrefactory);
	for(ent <- entityWithProperties) {
		println(readable(ent));
		println("properties:");
		for(p <- entityWithProperties[ent]) {
			println("  <p[0]>:<readable(p[1])>");
		}
	}
}

public void PrintResultsFiltered(Resource nrefactory) {
	map[Entity, set[tuple[str,Entity]]] entityWithProperties = CollectTypesAndProperties(nrefactory);
	for(ent <- entityWithProperties) {
		bool first = true;
		for(p <- entityWithProperties[ent], /class("CSharpTokenNode") !:= p[1], /class("DomNode") !:= p[1], /class("DomLocation") !:= p[1]) {
			if (first) {
				println(readable(ent));
				println("properties:");
				first = false;
			
			}
			println("  <p[0]>:<readable(p[1])>");
		}
	}
}

public void PrintPropertyHistogram(Resource nrefactory) {
	map[Entity, set[tuple[str,Entity]]] entityWithProperties = CollectTypesAndProperties(nrefactory);
	map[Entity, int] result = ();
	for(ent <- entityWithProperties) {
		for(p <- entityWithProperties[ent]) {
			result[p[1]] ? 0 += 1;
		}
	}
	for (r <- result) {
		println("<readable(r)> : <result[r]> (</enum(_,_) := r>)");
	}
}
//map[Entity, rel[str,Entity]] entityWithProperties = CollectTypesAndProperties(nrefactory);
public void ShowRelations(map[Entity, rel[str,Entity]] entityWithProperties) {
	entityWithProperties = ( e : {<st, ent> | <st, ent> <- entityWithProperties[e], /class("CSharpTokenNode") !:= ent, /class("DomLocation") !:= ent }
		| e <- entityWithProperties);
	println("digraph G {");
	/*for (e <- {domain(entityWithProperties) + { r<1> | r <- range(entityWithProperties)} }) {
		println(last(e.id).name);
	}*/
	for (e <- entityWithProperties){
		for (p <- entityWithProperties[e]) {
			println("\"<readable(last(e.id))>\" -\> \"<readable(last(p[1].id))>\"");
		}
	}
	println("}");
	//nodes = [ box(text(last(e.id).name), id(last(e.id).name), width(50), height(15)) | e <- {domain(entityWithProperties) + { r<1> | r <- range(entityWithProperties)} }];
	//edges = [ [ edge([lineWidth(1)], last(e.id).name, last(p[1].id).name) | p <- entityWithProperties[e]] | e <- entityWithProperties ];
	//render(graph(nodes, edges, size(800)));
}
