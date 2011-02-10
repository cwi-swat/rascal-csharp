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
public map[Entity, list[tuple[str,Entity]]] CollectTypesAndProperties(Resource nrefactory)
{
  set[Entity] domTypes = {t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types};
  Entity domNode = head([e | e:entity([_*,class("DomNode")]) <- domTypes]);
  EntityRel rExtends = (nrefactory@extends)*;
  set[Entity] domClasses = {t | <t, domNode> <- rExtends};
  rExtends = {r | r <- rExtends, <_,Object> !:= r, r[0] in domClasses};
  set[Entity] nonAbstractClasses = {c | c <- domClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})};
  map[Entity, Id] domProperties = (entity(ids): p | /entity([ids*,p:property(_,_,_,_)]) <- nrefactory@properties, /entity(ids) := domClasses);
  return (c : [<p.name, p.propertyType> | p <- [domProperties[cl] | cl <- rExtends[c]]] | c <- nonAbstractClasses);
}

