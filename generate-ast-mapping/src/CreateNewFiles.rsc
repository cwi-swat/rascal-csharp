module CreateNewFiles

import CSharpNRefactory;
import GenerateProtobufFile;
import GenerateRascalFile;
import dotNet;
import IO;
// writeFilesFor("/home/davy/Personal/rascal-projects/rascal-csharp", nrefactory);
public void writeFilesFor(str projectRoot, Resource nrefactory) {
	structure = generateStructureFor(nrefactory);
	writeFile(|file://<projectRoot>/rascal-csharp/src/CSharp.rsc|, generateRascal(structure));
	writeFile(|file://<projectRoot>/ipc/csharp-ast-java.proto|, generateProtobuf(structure, false));
	writeFile(|file://<projectRoot>/ipc/csharp-ast-net.proto|, generateProtobuf(structure, true));
}