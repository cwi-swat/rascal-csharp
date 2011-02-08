module FilterDOMInformation

import CLRInfo;
import CSharp;
import dotNet;

import List;
import Map;
import IO;
import Set;
import Graph;

public Entity domRoot = entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), namespace("DomNode")]);

//  nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
public map[Entity, list[tuple[str,Entity]]] CollectTypesAndProperties(Resource nrefactory)
{

  domClasses = [t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types];
  nonAbstractClasses = [c | c <- domClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})];
  domProperties = {<entity(ids), p> | /entity([ids*,p:property(_,_,_)]) <- nrefactory@properties, /entity(ids) := domClasses};
  return (c : [<p.name, p.getter> | p <- domProperties[c]] | c <- nonAbstractClasses);
}