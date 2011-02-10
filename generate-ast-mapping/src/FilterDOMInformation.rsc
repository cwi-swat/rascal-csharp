module FilterDOMInformation

import CLRInfo;
import CSharp;
import dotNet;

import List;
import Map;
import IO;
import Set;
import Graph;

//  nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
public map[Entity, set[tuple[str,Entity]]] CollectTypesAndProperties(Resource nrefactory)
{
	set[Entity] domTypes = {t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types};
	Entity domNode = head([e | e:entity([_*,class("DomNode")]) <- domTypes]);
	EntityRel flattedExtends = (nrefactory@extends)*;
	set[Entity] domClasses = {t | <t, domNode> <- flattedExtends};
	flattedExtends = {r | r <- flattedExtends, <_,Object> !:= r, r[0] in domClasses};
	set[Entity] nonAbstractClasses = {c | c <- domClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})};
	map[Entity, Id] domProperties = (entity(ids): p | /entity([ids*,p:property(_,_,_,_)]) <- nrefactory@properties, /entity(ids) := domClasses);
	return (c : {<p.name, p.propertyType> | p <- {domProperties[cl] | cl <- flattedExtends[c]}} | c <- nonAbstractClasses);
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