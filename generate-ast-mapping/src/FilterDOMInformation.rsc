module FilterDOMInformation

import CLRInfo;
import CSharp;
import dotNet;

import List;
import Map;
import IO;
import Set;

//  nrefactory = readCLRInfo(["../../../../../rascal-csharp/lib/ICSharpCode.NRefactory.dll"]);
public map[Entity, list[tuple[str,Entity]]] CollectTypesAndProperties(Resource nrefactory)
{
  domClasses = [t | t:entity([namespace("ICSharpCode"), namespace("NRefactory"), namespace("CSharp"), _]) <- nrefactory@types];
  nonAbstractClasses = [c | c <- domClasses, isEmpty((nrefactory@modifiers)[c] & {abstract()})];
  domProperties = [p | p:/entity([ids*,property(_,_,_)]) <- nrefactory@properties, /entity(ids) := nonAbstractClasses];
  return (c : [<p.name, p.getter> | /entity([ids*, p:property(_,_,_)]) <- domProperties, ids == c.id ] | c <- nonAbstractClasses);
}