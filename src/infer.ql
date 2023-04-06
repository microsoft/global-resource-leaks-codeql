/**
 * @name Inference of Annotations for Resource Leak Checker (RLC) 
 * @description Inferring annotations for Resource Leak Analysis.
 * @kind problem
 * @precision high
 * @problem.severity recommendation
 * @id c/infer-resource-leak-attributes
 * @tags correctness
 */

 import csharp
 import Dispose
 import semmle.code.csharp.commons.Disposal
 import semmle.code.csharp.frameworks.System
 import semmle.code.csharp.commons.Collections
 import semmle.code.csharp.dataflow.internal.DataFlowPrivate
 
 //-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //----------- Identifying the test code--------------------------------------------------------------------------
 
private class TestNamespace extends Namespace
{
    TestNamespace()
    {
        this.getQualifiedName().regexpMatch(".*[T|t]est.*")
    }
     
    predicate isTestNamespaceObject(Callable c)
    {
        this.getFile() = c.getLocation().getFile()
    }
}
 
predicate isInMockOrTestFile(Element c) // For disabling the inference of test code
{
    c.getLocation().getFile().getBaseName().regexpMatch(".*[M|m]ock.*") or
    c.getLocation().getFile().getBaseName().regexpMatch(".*[T|t]est.*") or
    exists(TestNamespace tns | tns.isTestNamespaceObject(c))
}
 
 
 //------------------------Predicates for Inferring Annotations------------------------------------------------------------------------------------------------------------------------------------------
 
predicate noEmptyMustCallAnnotation(Class c)
{
     not (c.fromLibrary() and exists(string str | c.hasName(str) and readAnnotation("Library","0","Class",str,"MustCall")))
}
 
 predicate readAnnotation(string filename, string lineNumber, string programElementType, string programElementName, string annotation)
{
    // Annotations on Library Code

    (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "StreamReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "BinaryReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "StreamWriter" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "BinaryWriter" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_Socket" and programElementType = "Method" and programElementName = "NetworkStream" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "2_SqlConnection" and programElementType = "Method" and programElementName = "SqlCommand" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0_SqlCommand" and programElementType = "Method" and programElementName = "ExecuteReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "Task" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "StringReader" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "MemoryStream" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Method" and programElementName = "CancellationTokenSource" and annotation = "NonOwning")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "StringTokenizer" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "Process" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "StringWriter" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "MemoryCache" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "PollingCounter" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "IncrementingPollingCounter" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "FeedIterator" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "1_String" and programElementType = "Method" and programElementName = "Open" and annotation = "Owning")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "SubscriptionToken" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "CountdownEvent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0_Socket" and programElementType = "Method" and programElementName = "Accept" and annotation = "NonOwning")
    or (filename = "Library" and lineNumber = "1_FileStream" and programElementType = "Method" and programElementName = "CreateFromFile" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_MemoryMappedFile" and programElementType = "Method" and programElementName = "CreateViewByteBuffer" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ServiceProvider" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Method" and programElementName = "EnsureSuccessStatusCode" and annotation = "NonOwning")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "StringContent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "XmlNodeList" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "DataInputStream" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "X509Certificate2" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "PerformanceCounter" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "PowerShell" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "X509Chain" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "X509Certificate" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "DataTable" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "2_SecureString" and programElementType = "Method" and programElementName = "PSCredential" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_XmlReader" and programElementType = "Method" and programElementName = "ReadObject" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_XmlWriter" and programElementType = "Method" and programElementName = "Create" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_HttpMessageHandler" and programElementType = "Method" and programElementName = "HttpClient" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_TextReader" and programElementType = "Method" and programElementName = "Create" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_TextWriter" and programElementType = "Method" and programElementName = "Create" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "TableServiceContext" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "RNGCryptoServiceProvider" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HttpRequestMessage" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HttpResponseMessage" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ObjectResult" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "UnityContainer" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ObjectContent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "StreamContent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ByteArrayContent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ImageList" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "JoinableTaskContext" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HeaderDelimitedMessageHandler" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ContainerControlledLifetimeManager" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "CMKCosmosDbStore" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "SecureString" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ReaderWriterLockSlim" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "PooledStopwatch" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "WindowPane" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ToolWindowPane" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "LoggerFactory" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "DbContext" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "1_DbConnection" and programElementType = "Method" and programElementName = "DbContext" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HashAlgorithm" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "SHA256" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "WebRequestHandler" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "ShellSettingsManager" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "PageSetupDialog" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "JsonMessageFormatter" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "XmlTextReader" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "XmlTextReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "2_Stream" and programElementType = "Method" and programElementName = "XmlTextReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "2_TextReader" and programElementType = "Method" and programElementName = "XmlTextReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_CancellationTokenSource" and programElementType = "Method" and programElementName = "Exchange<CancellationTokenSource>" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_CancellationToken" and programElementType = "Method" and programElementName = "CreateLinkedTokenSource" and annotation = "NonOwning")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "JsonDocument" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "AsyncSemaphore" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "DynamicCertificateValidatorFactory" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "JsonReader" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HttpContent" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "HttpClientHandler" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "TelemetryConfiguration" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "0" and programElementType = "Class" and programElementName = "Cursor" and annotation = "MustCall")
    or (filename = "Library" and lineNumber = "1_Stream" and programElementType = "Method" and programElementName = "InputStreamWrapper" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "1_TextReader" and programElementType = "Method" and programElementName = "JsonTextReader" and annotation = "MustCallAlias")
    or (filename = "Library" and lineNumber = "0_DbCommand" and programElementType = "Parameter" and programElementName = "this" and annotation = "Owning")
}
 

predicate checkForResourceType(RefType type)
{
    (type instanceof Generic and exists(RefType btype | btype = type.getABaseType() and checkForResourceType(btype)))
    or
    (type instanceof CollectionType and exists(RefType t | t = type.getAChild*() and type != t and checkForResourceType(t)))
    or
    (not type instanceof Generic and not type instanceof CollectionType and type.fromLibrary() and noEmptyMustCallAnnotation(type) and type instanceof DisposableType)
}
 
predicate hasCreateMustCallFor(Method c, Member p) 
{
    exists(Assignment assign, FieldWrite fw, Field f | f = p and 
        assign.getEnclosingCallable() = c and 
        assign.getLValue() = fw and f = fw.getTarget() and
        (not fw.hasQualifier() or fw.hasThisQualifier()) and 
        isOwningField(f) and
        not assign.getRValue().getValue()="null" and
        not exists(MethodCall release, FieldAccess fa, Method m |
            release.getEnclosingCallable() = c and 
            ((release.getQualifier() = fa and fa.getTarget() = f and
                m = release.getARuntimeTarget() and
                isInMustCall(f.getType(), m))
                or
                (hasEnsuresCalledMethods(release.getARuntimeTarget(), f, m))) 
            and
            // release.reachableFrom(assign.getRValue())
            DataFlow::localFlow(DataFlow::exprNode(fw), DataFlow::exprNode(fa))
        )
    )
    or
    exists(Assignment assign, PropertyWrite fw, Property f | f = p and 
        assign.getEnclosingCallable() = c and 
        assign.getLValue() = fw and f = fw.getTarget() and
        (not fw.hasQualifier() or fw.hasThisQualifier()) and 
        isOwningProperty(f) and
        not assign.getRValue().getValue()="null" and
        not exists(MethodCall release, PropertyAccess fa, Method m |
            release.getEnclosingCallable() = c and 
            ((release.getQualifier() = fa and fa.getTarget() = f and
                m = release.getARuntimeTarget() and
                isInMustCall(f.getType(), m))
                or
                (hasEnsuresCalledMethods(release.getARuntimeTarget(), f, m))) 
            and
            // release.reachableFrom(assign.getRValue())
            DataFlow::localFlow(DataFlow::exprNode(fw), DataFlow::exprNode(fa))
        )
    )
    or
    exists(Class cl, MethodCall mc, Field f | f = p and 
        mc.getEnclosingCallable() = c and
        mc.getARuntimeTarget() = cl.getAMember() and c = cl.getAMember() and
        (not mc.hasQualifier() or mc.hasThisQualifier()) and
        hasCreateMustCallFor(mc.getARuntimeTarget(), p) and
        not exists(MethodCall release, FieldAccess fa, Method m |
            release.getEnclosingCallable() = c and 
            ((release.getQualifier() = fa and fa.getTarget() = f and
                m = release.getARuntimeTarget() and 
                isInMustCall(f.getType(), m))
                or
                (hasEnsuresCalledMethods(release.getARuntimeTarget(), p, m))) 
            and
            release.reachableFrom(mc))
    )
    or
    exists(Class cl, MethodCall mc, Property f | f = p and 
        mc.getEnclosingCallable() = c and
        mc.getARuntimeTarget() = cl.getAMember() and c = cl.getAMember() and
        (not mc.hasQualifier() or mc.hasThisQualifier()) and
        hasCreateMustCallFor(mc.getARuntimeTarget(), p) and
        not exists(MethodCall release, PropertyAccess fa, Method m |
            release.getEnclosingCallable() = c and 
            ((release.getQualifier() = fa and fa.getTarget() = f and
                m = release.getARuntimeTarget() and 
                isInMustCall(f.getType(), m))
                or
                (hasEnsuresCalledMethods(release.getARuntimeTarget(), p, m))) 
            and
            release.reachableFrom(mc))
    )
}
 
 /**
  * Holds if there is a dataflow node `sink` which is aliased with the parameter p 
  * and there exists a sink for that
  */
predicate isOwningOnParam(Callable c, Parameter p)
{
    p = c.getParameter(_) and 
    exists(DataFlow::Node sink |
        c = sink.getEnclosingCallable() and sinkFor(c, sink)
        and isAlias(DataFlow::parameterNode(p), sink)
    )
}
 
 predicate isNotOwningOnMethod(Callable c)
 {
    exists(FieldRead fr, Field f, Expr e | fr = f.getAnAccess() and isOwningField(f) 
        and c = fr.getEnclosingCallable() and isReturnExpr(c, e)
        and checkAlias(DataFlow::exprNode(fr), DataFlow::exprNode(e))
    )
    or
    exists(PropertyRead fr, Property f, Expr e | fr = f.getAnAccess() and isOwningProperty(f) 
        and c = fr.getEnclosingCallable() and isReturnExpr(c, e)
        and checkAlias(DataFlow::exprNode(fr), DataFlow::exprNode(e))
    )
 }
 
 predicate hasMustCallAlias(Callable c, Parameter p)
 {
    p = c.getParameter(_) and 
    if (c.fromLibrary())
    then
        exists(string str, string sub, int i, int j | c.fromLibrary() and 
            sub = c.getParameter(i).getType().getName() and j = i + 1 and str = j.toString() + "_" + sub and 
            readAnnotation("Library",str,"Method",c.getName(),"MustCallAlias"))
        or
        (c.fromLibrary() and c.getNumberOfParameters() = 0 and readAnnotation("Library","0","Method",c.getName(),"MustCallAlias"))
    else if (c instanceof Constructor)
    then
        checkAllPathForConstructor((Constructor) c, DataFlow::parameterNode(p))
        //TODO it doesn't check all path       
    else 
        exists(Expr ret | isReturnExpr(c, ret) and
            isAlias(DataFlow::parameterNode(p), DataFlow::exprNode(ret)) and
            ret.getAControlFlowNode().postDominates(c.getEntryPoint())
        )
}
 
 predicate checkAllPathForConstructor(Constructor c, DataFlow::Node p) {
     exists(DataFlow::Node n | satisfyMCAOnConstructor(c, p, n) and n.getControlFlowNode().postDominates(c.getEntryPoint()) )
 }
 
predicate satisfyMCAOnConstructor(Constructor c, DataFlow::Node p, DataFlow::Node node) {
    exists(FieldWrite fw, Assignment assign, Parameter par |
        par = p.asParameter() and par = c.getParameter(_) and
        assign.getEnclosingCallable() = c and
        assign.getLValue() = fw and isOwningField(fw.getQualifiedDeclaration()) and
        assign.getRValue() = node.asExpr() and checkAlias(p, node)
    ) 
    // or
    // exists(PropertyWrite fw, Assignment assign |
    //     assign.getEnclosingCallable() = c and
    //     assign.getLValue() = fw and isOwningProperty(fw.getQualifiedDeclaration()) and
    //     assign.getRValue() = node.asExpr() and checkAlias(p, node)
    // ) 
    // or
    // exists(Call call , Constructor m, int i |
    //     call.getEnclosingCallable() = c and
    //     call.getARuntimeTarget() instanceof Constructor and
    //     m = call.getARuntimeTarget() and m != c and
    //     node.asExpr() = call.getArgument(i) and checkAlias(p, node) and
    //     hasMustCallAlias(m, m.getParameter(i))
    // )
}
 
predicate isReturnExpr(Callable c, Expr e)
{
    (c.canReturn(e) or c.canYieldReturn(e)) and (not c.getReturnType() instanceof VoidType)
    and (e.getType().containsTypeParameters() or checkForResourceType(e.getType()))
 }

  // Check if the call whose callee has an "Owning" parameter
  predicate checkParameterForSink(Call call, Expr arg)
  {
          exists(Parameter p, Callable c, int i | 
              c = call.getARuntimeTarget() and p = c.getParameter(i) and not p.isParams() 
              and arg = call.getArgument(i) 
              and not exists(TernaryOperation op | op.getAnOperand() = arg.getAChildExpr*())
              and (isOwningOnParam(c, p) or mayBeDisposed(p))
          )
          or
          // Handles case with varargs
          exists(Parameter p, Callable c, int arg_count, int ind | 
              c = call.getARuntimeTarget() and p = c.getParameter(ind) and p.isParams() 
              and arg_count = call.getNumberOfArguments() and arg_count >= ind 
              and (isOwningOnParam(c, p) or mayBeDisposed(p))
          )
  }

  predicate isAssignmentToOwningMember(Callable c, DataFlow::Node node)
  {
    // Assignment to an Owning Field
    exists(FieldWrite fw, AssignExpr assign| node.asExpr() = assign.getRValue() and
        c = node.getEnclosingCallable() and
        assign.getLValue() = fw and isOwningField(fw.getTarget()) 
    )
    or
    // Assignment to an Owning Property
    exists(PropertyWrite fw, AssignExpr assign| node.asExpr() = assign.getRValue() and
        c = node.getEnclosingCallable() and
        assign.getLValue() = fw and isOwningProperty(fw.getTarget()) 
    )
  }
 
 predicate sinkFor(Callable c, DataFlow::Node node) {
    exists(MethodCall mc, Method m | mc.getQualifier() = node.asExpr() and
        c = node.getEnclosingCallable() and
        m = mc.getARuntimeTarget() and isInMustCall(m.getDeclaringType(), m)
    )
    or
    exists(Call call, Callable m, Expr arg | arg = call.getAnArgument() and 
        arg = node.asExpr() and
        c = node.getEnclosingCallable() and
        m = call.getARuntimeTarget() and m != c and
        checkParameterForSink(call, arg)
    )
    or
    // Assignment to an Owning Field
    exists(FieldWrite fw, AssignExpr assign| node.asExpr() = assign.getRValue() and
        c = node.getEnclosingCallable() and
        not c instanceof Constructor and
        assign.getLValue() = fw and isOwningField(fw.getTarget()) 
    )
    or
    // Assignment to an Owning Property
    exists(PropertyWrite fw, AssignExpr assign| node.asExpr() = assign.getRValue() and
        c = node.getEnclosingCallable() and
        not c instanceof Constructor and
        assign.getLValue() = fw and isOwningProperty(fw.getTarget()) 
    )
    or
    // Using statement
    exists(UsingStmt stmt | c = node.getEnclosingCallable() and node.asExpr() = stmt.getAnExpr())
}

/** It holds if method m is either "Close", "Dispose" or some method that exists in the [MustCall] annotaion written on class c. */
predicate isInMustCall(Class c, Method m) {
    m instanceof DisposeMethod
    or
    m.hasName("Close")
    or
    m.hasName("Dispose")
    // or
    // exists(Attribute a, string str | 
    //     a = c.getAnAttribute()
    //     and a.getType().hasName("MustCallAttribute")
    //     and str = "\"" + m.getName() + "\"" and str = a.getArgument(0).toString()
    // )
    // or
    // hasMustCall(c, m)
}
 
/**
* Holds if there is a local flow between `node1` and `node2` or there is resource alias relationship between `node1` and `node2`.
*/
 
predicate checkAlias(DataFlow::Node node1, DataFlow::Node node2)
{
    node1.getEnclosingCallable() = node2.getEnclosingCallable()
    and
    (
        DataFlow::localFlow(node1, node2)
        or
        exists(ForeachStmt stmt, Expr e1, Expr e2 | 
            e1 = stmt.getAVariable().getAnAccess() and e2 = stmt.getIterableExpr()
            and node1.asExpr() = e2 and node2.asExpr() = e1)
        or
        isResourceAlias(node1, node2)
        or
        exists(DataFlow::Node n | checkAlias(node1, n) and isAlias(n, node2))
    )
}
 
predicate isAlias(DataFlow::Node node, DataFlow::Node alias) {
    (sinkFor(alias.getEnclosingCallable(), alias) 
        or isReturnExpr(alias.getEnclosingCallable(), alias.asExpr()) 
        or isAssignmentToOwningMember(alias.getEnclosingCallable(), alias)
    ) 
    and checkAlias(node, alias)
}

predicate isMustCallAliasMethod(Callable c)
{
    exists(string str, string sub, int i, int j | c.fromLibrary() and 
        sub = c.getParameter(i).getType().getName() and j = i + 1 and str = j.toString() + "_" + sub and 
        readAnnotation("Library",str,"Method",c.getName(),"MustCallAlias"))
    or
    (c.fromLibrary() and c.getNumberOfParameters() = 0 and readAnnotation("Library","0","Method",c.getName(),"MustCallAlias"))
}
 
 /** Holds if there exists a resource alias relationship between node and alias. To do that it checks whether there exists a call that represents a callable that has [MustCallAlias] annotaion on some parameter and there is a alising relationship between the node and the argument passed to the call and also between the call and the alias node. */
predicate isResourceAlias(DataFlow::Node node, DataFlow::Node alias) {
    exists(Call call, Callable c, Parameter p, Expr arg |
        c = call.getARuntimeTarget() and p = c.getParameter(_) and not p.isParams()
        and arg = call.getArgumentForParameter(p) 
        and alias.asExpr() = call and node.asExpr() = arg
        and node.getEnclosingCallable() = alias.getEnclosingCallable()
        and ((c.fromLibrary() and isMustCallAliasMethod(c)) or (not c.fromLibrary() and hasMustCallAlias(c, p)))
    )
    or
    exists(Call call, Callable c, Parameter p, int i, int j, Expr arg |
        c = call.getARuntimeTarget() and p = c.getParameter(i) and p.isParams()
        and arg = call.getAnArgument() and j = call.getNumberOfArguments() and j >= i
        and alias.asExpr() = call and node.asExpr() = arg
        and node.getEnclosingCallable() = alias.getEnclosingCallable()
        and ((c.fromLibrary() and isMustCallAliasMethod(c)) or (not c.fromLibrary() and hasMustCallAlias(c, p)))
    )
}
 
 predicate hasEnsuresCalledMethods(Method c, Member p, Method m) {
    exists(MethodCall mc , FieldRead fr, Field f | f = p and
        fr.getEnclosingCallable() = c and checkForResourceType(f.getType()) and
        fr = mc.getQualifier().getAChildExpr*() and m = mc.getARuntimeTarget() and
        fr.getTarget() = f and sinkFor(c, DataFlow::exprNode(mc.getQualifier()))
        // isInMustCall(f.getType(), m)
        and not exists(AssignableDefinition def | c = def.getEnclosingCallable() and def.getTarget() = f and def.getSource().reachableFrom(fr) and not def.getSource() instanceof NullLiteral)
        // or exists(MethodCall call, Method callee | c = call.getEnclosingCallable() 
        //     and callee = call.getARuntimeTarget() and c != callee 
        //     and hasCreateMustCallFor(callee, f))
    )
    or
    exists(MethodCall mc , PropertyRead fr, Property f | f = p and 
        fr.getEnclosingCallable() = c and checkForResourceType(f.getType()) and
        fr = mc.getQualifier().getAChildExpr*() and m = mc.getARuntimeTarget() and
        fr.getTarget() = f and sinkFor(c, DataFlow::exprNode(mc.getQualifier()))
        // isInMustCall(f.getType(), m)
        and not exists(AssignableDefinition def | c = def.getEnclosingCallable() and def.getTarget() = f and def.getSource().reachableFrom(fr) and not def.getSource() instanceof NullLiteral)
        // or exists(MethodCall call, Method callee | c = call.getEnclosingCallable() 
        //     and callee = call.getARuntimeTarget() and c != callee 
        //     and hasCreateMustCallFor(callee, f))
    )
    or
    exists(Call call, Expr arg | c = call.getEnclosingCallable()
        and m = call.getARuntimeTarget() and arg = call.getAnArgument()
        and checkParameterForSink(call, arg)
        and arg.getAChildExpr*() = p.getAnAccess()
        // and isAlias(DataFlow::exprNode(p.getAnAccess()), DataFlow::exprNode(arg))
    )
}

// predicate hasMustCallAnnotation(Class cl)
// {
//     exists(Callable c | not cl.fromLibrary() and checkForResourceType(cl) and c = cl.getAMethod() and hasEnsuresCalledMethods(c, _, _))
//     or
//     exists(Class base | noEmptyMustCallAnnotation(cl) and hasMustCallAnnotation(cl) and base = cl.getBaseClass())
// }
 
predicate isOwningField(Field f) {
    exists(Method c, Method m | hasEnsuresCalledMethods(c, f, m))
}

predicate isOwningProperty(Property f) {
    exists(Method c, Method m | hasEnsuresCalledMethods(c, f, m))
}

string getRelativePathForPar(Parameter p)
{
    exists(Callable c, Class cl | 
        p = c.getParameter(_) and cl.getAMember() = c |
        result = cl.getNamespace().getQualifiedName() + "/" + p.getLocation().getFile().getBaseName())
}

string getRelativePathForMethod(Callable c)
{
    exists(Class cl | cl.getAMember() = c |
        result = cl.getNamespace().getQualifiedName() + "/" + c.getLocation().getFile().getBaseName())
}

string getRelativePathForClass(Class c)
{
    result = c.getNamespace().getQualifiedName() + "/" + c.getLocation().getFile().getBaseName()
}

string getRelativePathForMember(Member p)
{
    result = p.getDeclaringType().getNamespace().getQualifiedName() + "/" + p.getLocation().getFile().getBaseName()
}

string getRelativeNameForMember(Member p)
{
    result = p.getDeclaringType() + "." + p.getName()
}

Callable getInstantiatedMethods(Callable c, Parameter p)
{
    exists(Call call, Callable res, Class cl | p = c.getParameter(_) and c.isUnboundDeclaration()
            and res = call.getARuntimeTarget()
            and cl.getAMember() = c and cl.getAMember() = res
            and getRelativePathForMethod(c) = getRelativePathForMethod(res)
            and c.getLocation().getStartLine() = res.getLocation().getStartLine()
        | result = res
    )
}

string inferAnnotations(Element e)
{
    exists(RefType type, Callable c, string str | type = e and type.fromSource() and checkForResourceType(type) and c = type.getAMethod() and hasEnsuresCalledMethods(c, _, _) and
        str = getRelativePathForClass(type) + "," + type.getLocation().getStartLine() + ",Class," + type.getName() + ",MustCall/" + c.getName()
        | result = str
    )
    or
    exists(Callable c, Method m, Field f, Class cl, string str1, string str2 | 
        c =  e and c = cl.getAMember() and f = cl.getAMember() and checkForResourceType(f.getType()) and
        hasEnsuresCalledMethods(c, f, m) and
        str1 = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",EnsuresCalledMethods/" + getRelativeNameForMember(f) + "/" + m.getName() and 
        str2 = getRelativePathForClass(cl) + "," + cl.getLocation().getStartLine() + ",Class," + cl.getName() + ",MustCall/" + c.getName()
        | result = [str1, str2]
    )
    or
    exists(Callable c, Method m, Property f, Class cl, string str1, string str2 | 
        c =  e and c = cl.getAMember() and f = cl.getAMember() and checkForResourceType(f.getType()) and
        hasEnsuresCalledMethods(c, f, m) and
        str1 = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",EnsuresCalledMethods/" + getRelativeNameForMember(f) + "/" + m.getName() and 
        str2 = getRelativePathForClass(cl) + "," + cl.getLocation().getStartLine() + ",Class," + cl.getName() + ",MustCall/" + c.getName()
        | result = [str1, str2]
    )
    or
    exists(Field f, string str | e = f and
        checkForResourceType(f.getType()) and 
        isOwningField(f) and
        str = getRelativePathForMember(f) + "," + f.getLocation().getStartLine() + ",Field," + getRelativeNameForMember(f) + ",Owning"        
        | result = str
    )
    or
    exists(Property f, string str | e = f and
        checkForResourceType(f.getType()) and
        isOwningProperty(f) and
        str = getRelativePathForMember(f) + "," + f.getLocation().getStartLine() + ",Property," + getRelativeNameForMember(f) + ",Owning"        
        | result = str
    )
    or
    exists(Parameter p , Callable c | p = e and
        p = c.getParameter(_) and c.fromSource() and c.hasBody() and
        if p.getType().containsTypeParameters() and hasMustCallAlias(c, p) 
        then
            exists(string str1, string str2, string str3, Callable c1 | c1 = getInstantiatedMethods(c, p) and
                str1 = getRelativePathForPar(p) + "," + p.getLocation().getStartLine() + ",Parameter," + p.getName() + ",MustCallAlias" and 
                str2 = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",MustCallAlias" and
                str3 = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c1.getName() + ",MustCallAlias"
                | result = [str1, str2, str3])
        else if checkForResourceType(p.getType()) and hasMustCallAlias(c, p) 
        then
            exists(string str1, string str2 |
                str1 = getRelativePathForPar(p) + "," + p.getLocation().getStartLine() + ",Parameter," + p.getName() + ",MustCallAlias" and 
                str2 = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",MustCallAlias"
                | result = [str1, str2])
        else
            result = ""
    )
    or
    exists(Parameter p , Callable c | p = e and
        // (p.getType().containsTypeParameters() or checkForResourceType(p.getType())) and
        p = c.getParameter(_) and c.fromSource() and c.hasBody() and isOwningOnParam(c, p) |
        result = getRelativePathForPar(p) + "," + p.getLocation().getStartLine() + ",Parameter," + p.getName() + ",Owning"
    )
    or
    exists(Callable c, Member f | 
        e = c and hasCreateMustCallFor(c, f) | 
        result = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",CreateMustCallFor/" + getRelativeNameForMember(f)
    )
    or
    exists(Callable c | 
        e = c and isNotOwningOnMethod(c) | 
        result = getRelativePathForMethod(c) + "," + c.getLocation().getStartLine() + ",Method," + c.getName() + ",NonOwning")
    or
        result = ""
}

from Element e, string str
where   not isInMockOrTestFile(e) and // Ignore the test code
        str = inferAnnotations(e) and str != ""
        // and e.getLocation().getFile().getBaseName().regexpMatch("")
select e, str

