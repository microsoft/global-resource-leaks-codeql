/**
 * @name Resource Leak Analysis (RLA) (for all types)
 * @description Resource Leak Analysis with Annotations (separately provided in a predicate).
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id cs/csharp-resource-leak-checker-for-all-types
 * @tags efficiency
 *       maintainability
 */

 import csharp
 import Dispose
 import semmle.code.csharp.commons.Disposal
 import semmle.code.csharp.frameworks.System
 import semmle.code.csharp.commons.Collections
 
 //--------------------------Specifying source and sink for RL----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 predicate isSource(DataFlow::Node node)
 {
     // Object creation - R = new Resource() where 'R' is a local reference/instance variable and "Resource" is a constructor
     node.asExpr() = any(ObjectCreation disposable | disposable = getAllSourcesForObjectCreation() | disposable)
     or
     // Parameter 'p' with either "Owning" annotation or whose type is ResourceType
     node.asParameter() = any(Parameter p | isOwningParameter(p) | p)
     or
     // Assignment 'a' - R = getResource() where 'R' is a local reference/instance variable and "getResource" is a method whose return-type is ResourceType
     node.asExpr() = any(Callable c, Call call | c = call.getARuntimeTarget() and getInterSourceAD(c, call) | call)
     or
     // Call to a method with annotation "CreateMustCallFor"
     node.asExpr() = any(Call call, Member f | hasCreateMustCallFor(call.getARuntimeTarget(), f) | call)
 }
 
 predicate isSink(DataFlow::Node node)
 {
     exists(UsingStmt stmt | node.asExpr() = stmt.getAnExpr())
     or
     // Argument 'arg' call to a method whose corresponding parameter has "Owning" annotation
     exists(Call call, Expr arg | arg = call.getAnArgument() and checkParameterForSink(call, arg) | node.asExpr() = arg)
     or
     // Call to Dispose or Close or a method 'm' with "EnsuresCalledMethods" annotation
     exists(MethodCall mc, Method m | m = mc.getARuntimeTarget() and
         (
             m instanceof DisposeMethod 
             or
             m.hasName("Close") 
             or 
             exists(Member f, Callable c | hasEnsuresCalledMethods(m, c, f))
             or
             isInMustCall(m.getDeclaringType(), m)
         )
         and node.asExpr() = mc.getQualifier()
     )
     or
     exists(Expr exp | exp = getAssignmentToOwningMember() and exp = node.asExpr())
     or
     // Sink is the method 'M' with "CreateMustCallFor" annotation that contains a call to a method 'C' with "CreateMustCallFor" annotation for the same member
     exists(Call call, Member f | checkEncapsulationMethodHasCreateMustCallForAnnotation(call, f) and call.(MethodCall).getQualifier() = node.asExpr())
     or
     // Return statement whose type is ResourceType
     exists(Expr e, Callable c | e = node.asExpr() and c = e.getEnclosingCallable() and isReturnExpr(c, e) and isOwningMethod(c))
     or
     // Things that are added to a collection of some kind are likely to escape the scope
     exists(MethodCall mc | mc.getAnArgument() = node.asExpr() | mc.getTarget().hasName("Add"))
     or 
     exists(AssignableDefinition def, Member f | node.asExpr() = def.getSource().getAChildExpr*() and f = def.getTarget() and (isOwningField(f.(Field)) or isOwningProperty(f.(Property))))
 }
 
 predicate subsetSink(DataFlow::Node node)
 {
     // Argument 'arg' call to a method whose corresponding parameter has "Owning" annotation
     exists(Call call, Expr arg | arg = call.getAnArgument() and checkParameterForSink(call, arg) | node.asExpr() = arg)
     or
     // Call to Dispose or Close or a method 'm' with "EnsuresCalledMethods" annotation
     exists(MethodCall mc, Method m | m = mc.getARuntimeTarget() and
         (
             m instanceof DisposeMethod 
             or
             m.hasName("Close") 
             or 
             exists(Member f, Callable c | hasEnsuresCalledMethods(m, c, f))
             or
             isInMustCall(m.getDeclaringType(), m)
         )
         and node.asExpr() = mc.getQualifier()
     )
     or
     // Things that are added to a collection of some kind are likely to escape the scope
     exists(MethodCall mc | mc.getAnArgument() = node.asExpr() | mc.getTarget().hasName("Add"))
 }

 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Check Correctness of Annotations---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
predicate callToOtherMustCallAliasConstructors(Callable caller, Parameter p)
{
    exists(Call call, Callable callee, Expr arg, Parameter pc |
        caller instanceof Constructor and p = caller.getParameter(_)
        and caller = call.getEnclosingCallable() and callee = call.getARuntimeTarget()
        and callee instanceof Constructor and pc = callee.getParameter(_)
        and arg = call.getArgumentForParameter(pc)
        and isAlias(DataFlow::parameterNode(p), DataFlow::exprNode(arg))
        and isMustCallAliasMethod(callee) and isMustCallAliasParameter(pc)
    )
}

predicate notReachableAlongRegularPaths(ControlFlow::Node const, ControlFlow::Node nd)
{
    nd.getEnclosingCallable().(Callable).getEntryPoint() = nd
    or
    notReachableAlongRegularPaths(const, nd.getAPredecessor()) and not nd = const and not exists(ThrowStmt stmt | stmt.getAControlFlowExitNode() = nd) and
    not exists(CatchClause cc | cc.getAControlFlowExitNode() =  nd)
}
 
predicate checkCorrectnessOfECM(Callable c, Callable m, Member p) 
{
    exists(MethodCall call, Expr exp1, Expr exp2, Field f | f = p and isOwningField(f) 
        and call.getEnclosingCallable() = c and call.getARuntimeTarget().getName() = m.getName()
        and exp1 = p.getAnAccess() and (exp2 = call.getQualifier().getAChildExpr*() or exp2 = call.getAnArgument())
        // and exp1.getAChildExpr*()  = exp2.getAChildExpr*())
        and exp1 = exp2)
        // and isAlias(DataFlow::exprNode(exp1), DataFlow::exprNode(exp2)))
    or
    exists(MethodCall call, Expr exp1, Expr exp2, Property f | f = p and isOwningProperty(f) 
        and call.getEnclosingCallable() = c and call.getARuntimeTarget().getName() = m.getName()
        and exp1 = p.getAnAccess() and (exp2 = call.getQualifier().getAChildExpr*() or exp2 = call.getAnArgument())
        // and exp1.getAChildExpr*()  = exp2.getAChildExpr*())
        and exp1 = exp2)
        // and isAlias(DataFlow::exprNode(exp1), DataFlow::exprNode(exp2)))
}
 
predicate checkCorrectnessOfCMF(Callable c, Member p) 
{
    exists(FieldWrite fw, Field f, AssignableDefinition def | f = p and fw = f.getAnAccess()
        and isOwningField(f) and c = fw.getEnclosingCallable() and fw = def.getTargetAccess()
        and not exists(DataFlow::Node sink, Expr exp | subsetSink(sink) and c = sink.getEnclosingCallable() and exp = sink.asExpr() and
            exp.reachableFrom(def.getSource())))
    or
    exists(PropertyWrite fw, Property f, AssignableDefinition def | f = p and fw = f.getAnAccess()
        and isOwningProperty(f) and c = fw.getEnclosingCallable() and fw = def.getTargetAccess()
        and not exists(DataFlow::Node sink, Expr exp | subsetSink(sink) and c = sink.getEnclosingCallable() and exp = sink.asExpr() and
            exp.reachableFrom(def.getSource())))
    or
    exists(Call call, Callable m | call.getEnclosingCallable() = c and m = call.getARuntimeTarget() and hasCreateMustCallFor(m, p)
        and not exists(DataFlow::Node sink, Expr exp | subsetSink(sink) and c = sink.getEnclosingCallable() and exp = sink.asExpr() and
            exp.reachableFrom(call)))
}
 
 predicate checkCorrectnessOfMustCallAlias(Parameter p, Callable c) 
 {
     exists(Expr ret | p = c.getParameter(_) and isReturnExpr(c, ret)
         and isAlias(DataFlow::parameterNode(p), DataFlow::exprNode(ret))
         and (ret.getAControlFlowNode().postDominates(c.getEntryPoint()) // Must property
                or exists(TernaryOperation op | op.getAnOperand() = ret.getAChildExpr*()))
         )
     or
     exists(Field f, AssignableDefinition def | p = c.getParameter(_) and 
         c instanceof Constructor and c = def.getEnclosingCallable()
         and f = def.getTarget() and isOwningField(f)
         and not def.getSource().getAChildExpr*() instanceof NullLiteral
         and isAlias(DataFlow::parameterNode(p), DataFlow::exprNode(def.getSource().getAChildExpr*()))
         and ((def.getAControlFlowNode().postDominates(c.getEntryPoint()) // Must property
         and def.getAControlFlowNode().dominates(c.getExitPoint())) // Must property
             or def.getSource().getAChildExpr*() instanceof NullCoalescingExpr)
         )
     or
     exists(Property f, AssignableDefinition def | p = c.getParameter(_) and 
         c instanceof Constructor and c = def.getEnclosingCallable()
         and f = def.getTarget() and isOwningProperty(f)
         and not def.getSource().getAChildExpr*() instanceof NullLiteral
         and isAlias(DataFlow::parameterNode(p), DataFlow::exprNode(def.getSource().getAChildExpr*()))
         and ((def.getAControlFlowNode().postDominates(c.getEntryPoint()) // Must property
         and def.getAControlFlowNode().dominates(c.getExitPoint())) // Must property       
             or def.getSource().getAChildExpr*() instanceof NullCoalescingExpr)
         )
     or
     callToOtherMustCallAliasConstructors(c, p)
 }
 
predicate missingCreateMustCallFor(Callable c)
{
    exists(AssignableDefinition a, Member f | a = hasOwningMemberDefinition(c, f) and not hasCreateMustCallFor(c, f) 
        and not exists(DataFlow::Node sink, Expr exp | isSink(sink) and c = sink.getEnclosingCallable() and exp = sink.asExpr() and
            exp.reachableFrom(a.getSource())
        )
    )
}
 
 predicate inconsistentMustCall(RefType type)
 {
     exists(RefType base, Callable c | checkForResourceType(type) and
         base = type.getABaseType() and isInMustCall(base, c) and not isInMustCall(type, c)
     )
 }
 
 predicate missingMustCallAlias(Callable c, Parameter p)
 {
     isMustCallAliasMethod(c) and not isMustCallAliasParameter(p)
     or
     isMustCallAliasParameter(p) and not isMustCallAliasMethod(c)
 }
 
 Member flagMissingAnnotation()
 {
     // exists(Field f | isOwningField(f) and not hasMustCallAnnotation(f.getDeclaringType()) | result = f)
     // or
     // exists(Property f | isOwningProperty(f) and not hasMustCallAnnotation(f.getDeclaringType()) | result = f)
     // or
     exists(Field f | isOwningField(f) and not hasEnsuresCalledMethods(_, _, f) | result = f)
     or
     exists(Property f | isOwningProperty(f) and not hasEnsuresCalledMethods(_, _, f) | result = f)
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Miscellaneous Predicates---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 Expr getRelevantExpression(AssignableDefinition a)
 {
     exists(Expr e | 
         e = a.getSource().getAChildExpr*().(Call).getAnArgument()
         or
         e = a.getSource().getAChildExpr*().(MethodCall).getQualifier()
         or
         e = a.getSource().getAChildExpr*()
         | result = e)
 }
 
 IfStmt isNullCheck(DataFlow::Node node)
 {
     exists(IfStmt stmt, Expr cond, Expr exp | 
         cond = stmt.getCondition() and cond.getAChildExpr*() instanceof NullLiteral
         and exp = node.asExpr()
         and stmt.getAChildStmt*() = exp.getEnclosingStmt()
         | result = stmt
     )
 }
 
 predicate checkNullCondition(DataFlow::Node node)
 {
     exists(IfStmt stmt, Expr cond, Expr exp | 
         cond = stmt.getCondition() and cond.getAChildExpr*() instanceof NullLiteral
         and exp = node.asExpr()
         and stmt.getAChildStmt*() = exp.getEnclosingStmt()
     )
 }
 
 predicate nextStatement(DataFlow::Node src, DataFlow::Node sink)
 {
     isSource(src) and isSink(sink) and 
     exists(BlockStmt stmt, Stmt s1, Stmt s2, int i, Expr e1, Expr e2 | 
         src.getEnclosingCallable() = stmt.getEnclosingCallable()
         and sink.getEnclosingCallable() = stmt.getEnclosingCallable()
         and e1 = src.asExpr() and e2 = sink.asExpr()
         and s1 = stmt.getStmt(i)
         and s1 = e1.getEnclosingStmt()
         and s2 = stmt.getStmt(i+1)
         and s2 = e2.getEnclosingStmt()
     )
 }
 
 ObjectCreation getAllSourcesForObjectCreation()
 {
     exists(ObjectCreation o, Callable caller, Callable callee, AssignableDefinition def, Field f | 
         def.getSource().getAChildExpr*() = o and
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and caller instanceof Constructor and f = def.getTarget() and not isOwningField(f) and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, AssignableDefinition def, Property f | 
         def.getSource().getAChildExpr*() = o and
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and caller instanceof Constructor and f = def.getTarget() and not isOwningProperty(f) and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, Field f, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o and 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor) and f = def.getTarget() and ((not isOwningField(f)) or f.isReadOnly())
         and not o = f.getInitializer() and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, Property f, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o and 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor) and f = def.getTarget() and ((not isOwningProperty(f)) or f.isReadOnly())
         and not o = f.getInitializer() and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, Field f, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o and 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor) and f = def.getTarget() and isOwningField(f) and not hasCreateMustCallFor(caller, f)
         and not o = f.getInitializer() and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, Property f, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o and 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor) and f = def.getTarget() and isOwningProperty(f) and not hasCreateMustCallFor(caller, f)
         and not o = f.getInitializer() and not f.isStatic() and checkForResourceType(f.getType())
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, LocalVariable v, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o and 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor) and v = def.getTarget()
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee | 
         caller = o.getEnclosingCallable() and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and not (caller instanceof Constructor)
         and not exists(AssignableDefinition def | def.getSource() = o)
         | result = o
     )
     or
     exists(ObjectCreation o, Callable caller, Callable callee, Field f, AssignableDefinition def | 
         def.getSource().getAChildExpr*() = o  
         and f = def.getTarget() and not isOwningField(f)
         and callee = o.(Call).getARuntimeTarget() and isOwningMethod(callee)
         and o = f.getInitializer() and not f.isStatic() and checkForResourceType(f.getType())
         and not caller = o.getEnclosingCallable() 
         | result = o
     )
 }

 predicate isReturnExpr(Callable c, Expr e)
 {
     exists(Expr exp | exp.getAChildExpr*() = e and  (c.canReturn(exp) or c.canYieldReturn(exp)) 
     and (e.getType().containsTypeParameters() or checkForResourceType(e.getType()))
     and not isNonOwningMethod(c))
 }
 
 // Assignment 'def' whose RHS has a call to a callable 'c' whose return-type is a ResourceType
 
predicate getInterSourceAD(Callable c, Call call)
{
        c = call.getARuntimeTarget() and not isNonOwningMethod(c)
        and isOwningMethod(c) // default "Owning" annotation if the return-type of callable 'c' is ResourceType, ideally
        and not (c instanceof Constructor or
            exists(AssignableDefinition def | def.getEnclosingCallable() = call.getEnclosingCallable() and def.getSource() = call and (isOwningField(def.getTarget()) or isOwningProperty(def.getTarget()))))
}
 
 Expr getAssignmentToOwningMember()
 {
     exists(Callable c, AssignableDefinition def, Field f, DataFlow::Node src, Expr exp |
         c = def.getEnclosingCallable() and not c instanceof Constructor
         and f = def.getTarget() and isOwningField(f) and not f.isReadOnly()
         and exp = getRelevantExpression(def)
         and isSource(src) and DataFlow::localFlow(src, DataFlow::exprNode(exp))
 //        and hasCreateMustCallFor(c, f)
         | result = exp  
     )
     or
     exists(Callable c, AssignableDefinition def, Property f, DataFlow::Node src, Expr exp |
         c = def.getEnclosingCallable() and not c instanceof Constructor
         and f = def.getTarget() and isOwningProperty(f) and not f.isReadOnly()
         and exp = getRelevantExpression(def)
         and isSource(src) and DataFlow::localFlow(src, DataFlow::exprNode(exp))
 //        and hasCreateMustCallFor(c, f)
         | result = exp  
     )
     or
     exists(Callable c, AssignableDefinition def, Field f, DataFlow::Node src, Expr exp |
         c = def.getEnclosingCallable() and c instanceof Constructor
         and f = def.getTarget() and isOwningField(f) 
         and exp = getRelevantExpression(def)
         and isSource(src) and DataFlow::localFlow(src, DataFlow::exprNode(exp))
         | result = exp  
     )
     or
     exists(Callable c, AssignableDefinition def, Property f, DataFlow::Node src, Expr exp |
         c = def.getEnclosingCallable() and c instanceof Constructor
         and f = def.getTarget() and isOwningProperty(f)
         and exp = getRelevantExpression(def)
         and isSource(src) and DataFlow::localFlow(src, DataFlow::exprNode(exp))
         | result = exp  
     )
 }
 
 // Check if the call whose callee has an "Owning" parameter
 predicate checkParameterForSink(Call call, Expr arg)
 {
         exists(Parameter p, Callable c, int i | 
             c = call.getARuntimeTarget() and p = c.getParameter(i) and not p.isParams() 
             and arg = call.getArgument(i) 
             and not exists(TernaryOperation op | op.getAnOperand() = arg.getAChildExpr*())
             and (isOwningParameter(p) or mayBeDisposed(p))
         )
         or
         // Handles case with varargs
         exists(Parameter p, Callable c, int arg_count, int ind | 
             c = call.getARuntimeTarget() and p = c.getParameter(ind) and p.isParams() 
             and arg_count = call.getNumberOfArguments() and arg_count >= ind 
             and (isOwningParameter(p) or mayBeDisposed(p))
         )
 }
 
 predicate checkEncapsulationMethodHasCreateMustCallForAnnotation(Call call, Member f)
 {
     exists(Callable callee, Callable caller | 
         caller = call.getEnclosingCallable() and hasCreateMustCallFor(caller, f)
         and callee = call.getARuntimeTarget() and hasCreateMustCallFor(callee, f)
     )
 }
 
 AssignableDefinition hasOwningMemberDefinition(Callable c, Member f) 
 {
     exists(AssignableDefinition a |
         c = a.getEnclosingCallable() and (not c instanceof Constructor) and f = a.getTarget() and (not a.getSource() instanceof NullLiteral)
         and (isOwningField(f.(Field)) or isOwningProperty(f.(Property)))
         | result = a
     )
 }
 
 predicate checkForSinkBeforeAssignmentInMethodWithCreateMustCallForAnnotation(AssignableDefinition a)
 {
     exists(DataFlow::Node sink | 
         sink.getEnclosingCallable() = a.getEnclosingCallable() 
         and sink.asExpr() != getRelevantExpression(a)
         and isSink(sink) and sink.getControlFlowNode().dominates(a.getAControlFlowNode())
     )
     or
     exists(IfStmt stmt, Expr cond | 
         cond = stmt.getCondition() and cond.getAChildExpr*() instanceof NullLiteral
         and stmt.getAChildStmt*() = a.getSource().getEnclosingStmt()
     )
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Predicates for Annotations----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
string getRelativePathForPar(Parameter p)
{
    exists(Callable c, Class cl | p = c.getParameter(_) and cl.getAMember() = c |
        result = cl.getNamespace().getQualifiedName() + "/" + p.getLocation().getFile().getBaseName())
}
  
 string getRelativePathForMethod(Callable c)
 {
     exists(Class cl | cl.getAMember() = c |
         result = cl.getNamespace().getQualifiedName() + "/" + c.getLocation().getFile().getBaseName())    
 }
  
 string getRelativePathForMember(Member p)
 {
     result = p.getDeclaringType().getNamespace().getQualifiedName() + "/" + p.getLocation().getFile().getBaseName()
 }
  
 string getRelativeNameForMember(Member p)
 {
     result = p.getDeclaringType() + "." + p.getName()
 }
  
 string getRelativePathForClass(RefType c)
 {
     result = c.getNamespace().getQualifiedName() + "/" + c.getLocation().getFile().getBaseName()
 }
  
 string getRelativePathForSource(DataFlow::Node src)
 {
    if src.getEnclosingCallable() instanceof LambdaExpr
    then
        exists(Class cl, LambdaExpr exp | exp = src.getEnclosingCallable() and cl.getAMember() = exp.getEnclosingCallable() |
            result = cl.getNamespace().getQualifiedName() + "/" + src.getLocation().getFile().getBaseName())
    else
        exists(Class cl | cl.getAMember() = src.getEnclosingCallable() |
            result = cl.getNamespace().getQualifiedName() + "/" + src.getLocation().getFile().getBaseName())
 }
 
 predicate isOwningParameter(Parameter p)
 {
     readAnnotation(getRelativePathForPar(p), p.getLocation().getStartLine().toString(),"Parameter",p.getName(),"Owning")
     // or
     // p.getAnAttribute().getType().hasName("OwningAttribute")
 }
 
 predicate isOwningMethod(Callable c)
 {
     readAnnotation(getRelativePathForMethod(c), c.getLocation().getStartLine().toString(),"Method",c.getName(),"Owning")
     or
     exists(string str, int i, int j, string sub | c.fromLibrary() and 
         sub = c.getParameter(i).getType().getName() and j = i + 1 and str = j.toString() + "_" + sub and
         readAnnotation("Library",str,"Method",c.getName(),"Owning"))
     or
     (c.fromLibrary() and c.getNumberOfParameters() = 0 and readAnnotation("Library","0","Method",c.getName(),"Owning"))
     or
     (not c.getName().regexpMatch("get_.*") and checkForResourceType(c.getReturnType()) and not isMustCallAliasMethod(c) and not isNonOwningMethod(c))
     or
     (c instanceof Constructor and checkForResourceType(c.getDeclaringType()) and not isMustCallAliasMethod(c) and not isNonOwningMethod(c))
     // or
     // c.(Method).getAnAttribute().getType().hasName("OwningAttribute")
     // or
     // c.(Constructor).getAnAttribute().getType().hasName("OwningAttribute")
 }
 
 predicate isNonOwningMethod(Callable c)
 {
     readAnnotation(getRelativePathForMethod(c), c.getLocation().getStartLine().toString(),"Method",c.getName(),"NonOwning")
     or
     (c.fromLibrary() and c.getNumberOfParameters() = 0 and readAnnotation("Library","0","Method",c.getName(),"NonOwning"))
     or
     exists(string str, int i, int j, string sub | c.fromLibrary() and 
         sub = c.getParameter(i).getType().getName() and j = i + 1 and str = j.toString() + "_" + sub and
         readAnnotation("Library",str,"Method",c.getName(),"NonOwning"))
     or
     (c.fromLibrary() and readAnnotation("Library",_,"Method",c.getName(),"NonOwning"))
     // or
     // c.(Method).getAnAttribute().getType().hasName("NonOwningAttribute")
     // or
     // c.(Constructor).getAnAttribute().getType().hasName("NonOwningAttribute")
 }
 
 predicate isOwningField(Field f)
 {
     readAnnotation(getRelativePathForMember(f), f.getLocation().getStartLine().toString(),"Field",getRelativeNameForMember(f),"Owning")
     // or
     // f.getAnAttribute().getType().hasName("OwningAttribute")
 }
 
 predicate isOwningProperty(Property f)
 {
     readAnnotation(getRelativePathForMember(f), f.getLocation().getStartLine().toString(),"Property",getRelativeNameForMember(f),"Owning")
     // or
     // f.getAnAttribute().getType().hasName("OwningAttribute")
 }
 
 predicate isMustCallAliasParameter(Parameter p)
 {
     readAnnotation(getRelativePathForPar(p), p.getLocation().getStartLine().toString(),"Parameter",p.getName(),"MustCallAlias")
     // or
     // p.getAnAttribute().getType().hasName("MustCallAliasAttribute")
 }
 
 predicate isMustCallAliasMethod(Callable c)
 {
     readAnnotation(getRelativePathForMethod(c), c.getLocation().getStartLine().toString(),"Method",c.getName(),"MustCallAlias")
     // or
     // c.(Method).getAnAttribute().getType().hasName("MustCallAliasAttribute")
     // or
     // c.(Constructor).getAnAttribute().getType().hasName("MustCallAliasAttribute")
     or
     exists(string str, string sub, int i, int j | c.fromLibrary() and 
         sub = c.getParameter(i).getType().getName() and j = i + 1 and str = j.toString() + "_" + sub and 
         readAnnotation("Library",str,"Method",c.getName(),"MustCallAlias"))
     or
     (c.fromLibrary() and c.getNumberOfParameters() = 0 and readAnnotation("Library","0","Method",c.getName(),"MustCallAlias"))
 }
 
 predicate hasEnsuresCalledMethods(Callable c, Callable m, Member p)
 {
     readAnnotation(getRelativePathForMethod(c), c.getLocation().getStartLine().toString(),"Method",c.getName(),"EnsuresCalledMethods/"+getRelativeNameForMember(p)+"/"+m.getName())
     // or
     // exists(Attribute a, string str1, string str2, Field f | 
     //     (a = c.(Method).getAnAttribute() or a = c.(Constructor).getAnAttribute())
     //     and a.getType().hasName("EnsuresCalledMethodsAttribute") and f = p
     //     and str1 = "\"" + f.getQualifiedName() + "\"" and str1 = a.getArgument(0).toString()
     //     and str2 = "\"" + m.getName() + "\"" and str2 = a.getArgument(1).toString()
     // )
     // or
     // exists(Attribute a, string str1, string str2, Property f | 
     //     (a = c.(Method).getAnAttribute() or a = c.(Constructor).getAnAttribute())
     //     and a.getType().hasName("EnsuresCalledMethodsAttribute") and f = p
     //     and str1 = "\"" + f.getQualifiedName() + "\"" and str1 = a.getArgument(0).toString()
     //     and str2 = "\"" + m.getName() + "\"" and str2 = a.getArgument(1).toString()
     // )
 }
 
 predicate hasCreateMustCallFor(Callable c, Member p)
 {
     readAnnotation(getRelativePathForMethod(c), c.getLocation().getStartLine().toString(),"Method",c.getName(),"CreateMustCallFor/"+getRelativeNameForMember(p))
     // or
     // exists(Attribute a, string str, Field f | 
     //     (a = c.(Method).getAnAttribute() or a = c.(Constructor).getAnAttribute())
     //     and a.getType().hasName("CreateMustCallForAttribute") and f = p
     //     and (str = "\"" + f.getQualifiedName() + "\"" or
     //         str = "\"" + f.getName() + "\"")
     //     and str = a.getArgument(0).toString()
     // )
     // or
     // exists(Attribute a, string str, Property f | 
     //     (a = c.(Method).getAnAttribute() or a = c.(Constructor).getAnAttribute())
     //     and a.getType().hasName("CreateMustCallForAttribute") and f = p
     //     and (str = "\"" + f.getQualifiedName() + "\"" or
     //         str = "\"" + f.getName() + "\"")
     //     and str = a.getArgument(0).toString()
     // )
 }
 
 predicate noEmptyMustCallAnnotation(Class c)
 {
     not readAnnotation(getRelativePathForClass(c), c.getLocation().getStartLine().toString(),"Class",c.getName(),"MustCall")
     and 
     not (c.fromLibrary() and exists(string str | c.hasName(str) and readAnnotation("Library","0","Class",str,"MustCall")))
     // and
     //    not exists(Attribute a, string str | 
     //    a = c.getAnAttribute()
     //    and a.getType().hasName("MustCallAttribute")
     //    and str = a.getArgument(0).toString() and str = ""
     //)
 }
 
 predicate hasMustCallAnnotation(Class c)
 {
     exists(string str | str.regexpMatch("MustCall/.*") and readAnnotation(getRelativePathForClass(c), c.getLocation().getStartLine().toString(),"Class",c.getName(),str))
     // or
     // exists(RefType type | type = basicTypes() and c = type and noEmptyMustCallAnnotation(c))
     // or
     // exists(Attribute a, string str | 
     //     a = c.getAnAttribute()
     //     and a.getType().hasName("MustCallAttribute")
     //     and str = a.getArgument(0).toString() and str != ""
     // )
     or
     exists(Class base | c.getBaseClass() = base and noEmptyMustCallAnnotation(c) and hasMustCallAnnotation(base))
 }
 
 predicate isInMustCall(Class c, Callable m)
 {
     readAnnotation(getRelativePathForClass(c), c.getLocation().getStartLine().toString(),"Class",c.getName(),"MustCall/"+m.getName())
     // or
     // exists(Attribute a, string str | 
     //     a = c.getAnAttribute()
     //     and a.getType().hasName("MustCallAttribute")
     //     and str = "\"" + m.getName() + "\"" and str = a.getArgument(0).toString()
     // )
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Identifying Aliases-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
predicate isResourceAlias(DataFlow::Node node, DataFlow::Node alias)
{
    node.getEnclosingCallable() = alias.getEnclosingCallable()
    and
    (
        exists(MethodCall call, Callable c, Parameter p, Expr arg |
            c = call.getARuntimeTarget() and p = c.getParameter(_) and not p.isParams()
            and arg = call.getArgumentForParameter(p) 
            and alias.asExpr() = call and node.asExpr() = arg
            and node.getEnclosingCallable() = alias.getEnclosingCallable()
            and ((c.fromLibrary() and isMustCallAliasMethod(c)) or (not c.fromLibrary() and isMustCallAliasMethod(c) and isMustCallAliasParameter(p)))
        )
        or
        exists(MethodCall call, Callable c, Parameter p, int i, int j, Expr arg |
            c = call.getARuntimeTarget() and p = c.getParameter(i) and p.isParams()
            and arg = call.getAnArgument() and j = call.getNumberOfArguments() and j >= i
            and alias.asExpr() = call and node.asExpr() = arg
            and node.getEnclosingCallable() = alias.getEnclosingCallable()
            and ((c.fromLibrary() and isMustCallAliasMethod(c)) or (not c.fromLibrary() and isMustCallAliasMethod(c) and isMustCallAliasParameter(p)))
        )
    )
}
predicate checkAlias(DataFlow::Node node1, DataFlow::Node node2)
{
    node1.getEnclosingCallable() = node2.getEnclosingCallable()
    and
    (
        node1 = node2
        or
        exists(Expr e1, Expr e2 | e1 = node1.asExpr() and e2 = node2.asExpr() and e1 = e2.getAChildExpr*())
        or
        (DataFlow::localFlow(node1, node2) and not exists(TernaryOperation op | op.getAnOperand() = node2.asExpr()))
        or
        exists(ForeachStmt stmt, Expr e1, Expr e2 | 
            e1 = stmt.getAVariable().getAnAccess() and e2 = stmt.getIterableExpr()
            and node1.asExpr() = e2 and node2.asExpr() = e1)
        or
        isResourceAlias(node1, node2)
        or
        exists(DataFlow::Node n | isAlias(node1, n) and checkAlias(n, node2))
    )
}
 
predicate isAlias(DataFlow::Node node1, DataFlow::Node node2)
{
    node1.getEnclosingCallable() = node2.getEnclosingCallable() and
    (isSource(node1) or exists(Parameter p | node1.asParameter() = p and isMustCallAliasParameter(p)))
    and isSink(node2) // Need to check this
    and checkAlias(node1, node2)
}
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Identifying Resource Types----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 


// Check for ResourceTypes recursively
 
predicate checkForResourceType(RefType type)
{
    (type instanceof Generic and exists(RefType btype | btype = type.getABaseType() and checkForResourceType(btype)))
    or
    (type instanceof CollectionType and exists(RefType t | t = type.getAChild*() and type != t and checkForResourceType(t)))
    or
    hasMustCallAnnotation(type)
    or
    exists(Field f | f = type.getAField() and isOwningField(f))
    or
    exists(Property f | f = type.getAProperty() and isOwningProperty(f))
    or
    (noEmptyMustCallAnnotation(type) and exists(RefType t | t = type.getABaseType() and type != t and checkForResourceType(t)))
    or
    (not type instanceof Generic and not type instanceof CollectionType and noEmptyMustCallAnnotation(type) and type instanceof DisposableType)
}
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Identifying Test Code----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 private class TestNamespace extends Namespace
 {
     TestNamespace()
     {
         this.getQualifiedName().regexpMatch(".*[T|t]est.*")
     }
     
     predicate isTestNamespaceObject(DataFlow::Node disposable)
     {
         this.getFile() = disposable.getLocation().getFile()
     }
 }
 
 predicate isInMockOrTestFile(DataFlow::Node disposable) // For disabling the inference of test code
 {
     disposable.getLocation().getFile().getBaseName().regexpMatch(".*[M|m]ock.*") or
     disposable.getLocation().getFile().getBaseName().regexpMatch(".*[T|t]est.*") or
     exists(TestNamespace tns | tns.isTestNamespaceObject(disposable))
 }

 predicate isInMockOrTestFileE(Element disposable) // For disabling the inference of test code
 {
     disposable.getLocation().getFile().getBaseName().regexpMatch(".*[M|m]ock.*") or
     disposable.getLocation().getFile().getBaseName().regexpMatch(".*[T|t]est.*") 
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //-----------------------Checking control-flow-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 LoopStmt isInLoop(DataFlow::Node node)
 {
     exists(LoopStmt s | s.getBody().getAChildStmt().getAChildExpr*() = node.getControlFlowNode().getElement().getAChildExpr*() |  result = s)
 }
 
 predicate isInSameLoop(DataFlow::Node src, DataFlow::Node sink) 
 {
     exists(ForeachStmt fs, LoopStmt s | s = isInLoop(src) and fs.getBody().getAChildExpr*() = sink.getControlFlowNode().getElement().getAChildExpr*() and fs.reachableFrom(s))
     or exists(| isInLoop(src) = isInLoop(sink))
 }
 
 predicate notInLoop(DataFlow::Node src, DataFlow::Node sink) 
 {
     not exists(LoopStmt s | s = isInLoop(src))
     and
     not exists(LoopStmt s | s = isInLoop(sink))
 }
 
 // node1.postDominates(node2)
 predicate doesPostDominate(DataFlow::Node node1, DataFlow::Node node2)
 {
     node1 = node2 or
     if (exists(Parameter p | p = node2.asParameter()))
     then
         getRelevantControlFlowNode(node1).postDominates(node2.getEnclosingCallable().(Callable).getEntryPoint())
     else
         ((not exists(TernaryOperation op | op.getAnOperand() = node2.asExpr()))
         and getRelevantControlFlowNode(node1).postDominates(node2.getControlFlowNode())
         )
 }
 
 // node1.dominates(node2)
 predicate doesDominate(DataFlow::Node node1, DataFlow::Node node2)
 {
     node1 = node2 or
     (isSink(node1) and exists(UsingStmt stmt | node1.asExpr() = stmt.getAnExpr()) and (not exists(TernaryOperation op | op.getAnOperand() = node2.asExpr()))
         and getRelevantControlFlowNode(node1).dominates(node2.getControlFlowNode())
     )
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 
 //--------------------------Data flow analysis----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 predicate belongToSameStmt(DataFlow::Node src, DataFlow::Node sink)
 {
     exists(Expr e1, Expr e2 | e1 = src.asExpr() and e2 = sink.asExpr() and e1.getEnclosingStmt() = e2.getEnclosingStmt())
 }
 
 predicate checkDataFlow(DataFlow::Node src, DataFlow::Node sink)
 {
     isSource(src) and isSink(sink) and src.getEnclosingCallable() = sink.getEnclosingCallable() and (belongToSameStmt(src, sink) or isAlias(src, sink))
 }
 
 predicate hasDataFlow(DataFlow::Node src, DataFlow::Node sink)
 {
     checkDataFlow(src, sink) 
     and 
     (
         isInSameLoop(src, sink)
         or
         (notInLoop(src, sink) and (belongToSameStmt(src, sink) or doesPostDominate(sink, src) or doesDominate(sink, src) or nextStatement(src, sink)))
     )
 }
 
 predicate mayNotBeDisposed(DataFlow::Node src)
 {
     isSource(src) and not suppressAlertsWithAnnotations(src) and not exists(DataFlow::Node sink | hasDataFlow(src, sink))
     or
     // Parameter 'p' with "MustCallAlias" annotation does not satisfy the semantics of the annotation
     (exists(Parameter p, Callable c | 
         src.asParameter() = p and p = c.getParameter(_) 
         and isMustCallAliasParameter(p) and not checkCorrectnessOfMustCallAlias(p, c)
     ) and not suppressAlertsWithAnnotations(src))
     or
     // No Disposal before the reassignment
     (exists(AssignableDefinition a, Member f, Callable c | a = hasOwningMemberDefinition(c, f) 
         and hasCreateMustCallFor(c, f)
         and src.asExpr() = a.getSource().getAChildExpr*()
         and not checkForSinkBeforeAssignmentInMethodWithCreateMustCallForAnnotation(a) 
     ) and not suppressAlertsWithAnnotations(src))
 }
 
predicate reachableWithoutDisposal(DataFlow::Node src, ControlFlow::Node nd)
{
    (isSource(src) and 
    if exists(Parameter p | src.asParameter() = p)
    then
        nd = src.getEnclosingCallable().getEntryPoint()
    else
        nd = src.getControlFlowNode()
    )
    or
    (reachableWithoutDisposal(src, nd.getAPredecessor()) and not 
        exists(DataFlow::Node sink | (doesDominate(sink, src) or checkNullCondition(sink) or belongToSameStmt(src, sink) or nextStatement(src, sink) or sink.getControlFlowNode() = nd) and checkDataFlow(src, sink)))
}
 
 string mayNotBeDisposedAlt(Element e)
 {
     exists(Parameter p, DataFlow::Node src | p = e and src = DataFlow::parameterNode(p) and 
         checkForResourceType(src.getType()) and not isInMockOrTestFile(src) and
         isSource(src) and not suppressAlertsWithAnnotationsE(p) 
         and reachableWithoutDisposal(src, src.getEnclosingCallable().getExitPoint())
        | 
            if p.getType().fromLibrary()
            then
                result = "Verifying Owning Parameter (" + src.getType() + " - L) " + p.getName() + " in method " + src.getEnclosingCallable().getName()
            else
            result = "Verifying Owning Parameter (" + src.getType() + "- C) " + p.getName() + " in method " + src.getEnclosingCallable().getName()
         )
     or
     exists(Expr exp, DataFlow::Node src | exp = e and src = DataFlow::exprNode(exp) and 
         checkForResourceType(src.getType()) and not isInMockOrTestFile(src) and
         isSource(src) and not suppressAlertsWithAnnotationsE(exp) 
         and reachableWithoutDisposal(src, src.getEnclosingCallable().getExitPoint())
         | 
            if src.getType().fromLibrary()
            then
                result = "Resource Leak (" + src.getType() + "- L) " + " in method " + src.getEnclosingCallable().getName()
            else
                result = "Resource Leak (" + src.getType() + "- C) " + " in method " + src.getEnclosingCallable().getName()
        )
     or
     exists(Expr exp, DataFlow::Node src, Field f | exp = e and src = DataFlow::exprNode(exp) 
         and not isOwningField(f) and f.getInitializer() = exp and
         checkForResourceType(src.getType()) and not isInMockOrTestFile(src) and
         isSource(src) and not suppressAlertsWithAnnotationsE(exp)
         |
         if f.isReadOnly() then
            if f.getType().fromLibrary()
            then
                result = "Resource Leak (" + src.getType() + "- L) " + " in method " + src.getEnclosingCallable().getName()
            else
                result = "Resource Leak (" + src.getType() + "- C) " + " in method " + src.getEnclosingCallable().getName()
         else    
            if f.getType().fromLibrary()
            then
                 result = "Resource Leak allocated at Non-Readonly Field initialization (" + src.getType() + "- L) " + f.getName() + " in class " + f.getDeclaringType()
            else
                 result = "Resource Leak allocated at Non-Readonly Field initialization (" + src.getType() + "- C) " + f.getName() + " in class " + f.getDeclaringType()
         ) 
     or
     // Parameter 'p' with "MustCallAlias" annotation does not satisfy the semantics of the annotation
     exists(Parameter p, Callable c, DataFlow::Node src | p = e and 
         src.asParameter() = p and p = c.getParameter(_) and
         checkForResourceType(src.getType()) and not isInMockOrTestFile(src) and
         isMustCallAliasParameter(p) and not checkCorrectnessOfMustCallAlias(p, c)
         and not suppressAlertsWithAnnotationsE(p)
         | 
            if p.getType().fromLibrary()
            then
                result = "Verifying MustCallAlias Parameter (" + src.getType() + "- L) " + p.getName() + " in method " + src.getEnclosingCallable().getName()
            else
                result = "Verifying MustCallAlias Parameter (" + src.getType() + "- C) " + p.getName() + " in method " + src.getEnclosingCallable().getName()
                )
     or
     // No Disposal before the reassignment
     exists(AssignableDefinition a, Member f, Callable c, DataFlow::Node src, Expr exp | c = e and a = hasOwningMemberDefinition(c, f) 
         and hasCreateMustCallFor(c, f) and
         exp = a.getSource().getAChildExpr*() and exp = src.asExpr() and
         checkForResourceType(src.getType()) and not isInMockOrTestFile(src)
         and not checkForSinkBeforeAssignmentInMethodWithCreateMustCallForAnnotation(a) 
         and not suppressAlertsWithAnnotationsE(exp)
         | 
            if src.getType().fromLibrary()
            then
                result = "Older Resource Leak not deallocated (" + src.getType() + "- L) " + f.getName() + " in method " + c.getName()
            else
                result = "Older Resource Leak not deallocated (" + src.getType() + "- C) " + f.getName() + " in method " + c.getName()
         )
     or
     // No EnsuresCalledMethods attribute associated to an Owning Field/Property
     exists(Member f | f = e and f = flagMissingAnnotation() and not suppressAlertsWithAnnotationsM(f) and not isInMockOrTestFileE(e)
     |
     if (f.(Field).isReadOnly() or f.(Property).isReadOnly()) then
        result = "Missing ECM for ReadOnly Owning Field/Property " + f.getName() + " in class " + f.getDeclaringType() + "- C"
     else    
        result = "Missing ECM for Non-ReadOnly Owning Field/Property " + f.getName() + " in class " + f.getDeclaringType() + "- C"
     )
     or
     // No CreateMustCallFor attribute associated to a method that contains an assignment to an Owning Field/Property
     exists(Method m | m = e and missingCreateMustCallFor(m) and not suppressAlertsWithAnnotationsMet(m) and not isInMockOrTestFileE(e)
     | result = "Missing CMC on method " + m.getName() + "- C"
     )
     or
     // Method with EnsuresCalledMethods attribute does not contain the call to dispose the resource referenced by the Field/Property
     exists(Method c, Method m, Member f | e = c and hasEnsuresCalledMethods(c, m, f) and not checkCorrectnessOfECM(c, m, f) 
        and not isInMockOrTestFileE(e) and not suppressAlertsWithAnnotationsMet(c)
        | 
        if (f.(Field).isReadOnly() or f.(Property).isReadOnly()) then
            result = "Verifying ECM Annotation for Readonly Field/Property " + f.getName() + " in method " + m.getName() + "- C"
        else    
            result = "Verifying ECM Annotation for Non-Readonly Field/Property " + f.getName() + " in method " + m.getName() + "- C"
        )
     or
     // Method with CreateMusTCallFor attribute does not contain an assignment to an Owning Field/Property
     exists(Method c, Member f | c = e and hasCreateMustCallFor(c, f) and not checkCorrectnessOfCMF(c, f) 
        and not isInMockOrTestFileE(e) and not suppressAlertsWithAnnotationsMet(c)
        | 
        if (f.(Field).isReadOnly() or f.(Property).isReadOnly()) then
            result = "Verifying CMC Annotation for Readonly Field/Property " + f.getName() + " in method " + c.getName() + "- C"
        else    
            result = "Verifying CMC Annotation for Non-Readonly Field/Property " + f.getName() + " in method " + c.getName() + "- C"
     )
 }
 
 ControlFlow::Node getRelevantControlFlowNode(DataFlow::Node sink)
 {
     if exists(IfStmt stmt | stmt = isNullCheck(sink))
     then
         result = isNullCheck(sink).getAControlFlowNode()
     else
         result = sink.getControlFlowNode()
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Logic for suppressing known alerts---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 predicate suppressAlertsWithAnnotations(DataFlow::Node src)
 {
     readAnnotation(getRelativePathForSource(src), src.getLocation().getStartLine().toString(),_,_,"Suppress")
 }
 
 predicate suppressAlertsWithAnnotationsMet(Callable c)
 {
     readAnnotation(getRelativePathForMethod(c),c.getLocation().getStartLine().toString(),_,_,"Suppress")
 }
 
 predicate suppressAlertsWithAnnotationsM(Member f)
 {
     readAnnotation(getRelativePathForMember(f),f.getLocation().getStartLine().toString(),_,_,"Suppress")
 }
 
 predicate suppressAlertsWithAnnotationsE(Element e)
 {
     exists(DataFlow::Node src, Parameter p | p = e and src.asParameter() = p 
         and readAnnotation(getRelativePathForSource(src), src.getLocation().getStartLine().toString(),_,_,"Suppress"))
     or
     exists(DataFlow::Node src, Expr exp | exp = e and src.asExpr() = exp 
         and readAnnotation(getRelativePathForSource(src), src.getLocation().getStartLine().toString(),_,_,"Suppress"))
     or
     exists(DataFlow::Node src, Parameter p | p = e and src.asParameter() = p 
         and readAnnotation(getRelativePathForSource(src), src.getLocation().getStartLine().toString(),_,_,"TP-Suppress"))
     or
    exists(DataFlow::Node src, Expr exp | exp = e and src.asExpr() = exp 
         and readAnnotation(getRelativePathForSource(src), src.getLocation().getStartLine().toString(),_,_,"TP-Suppress"))
 }
 
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //--------------------------Filtering Alerts---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 bindingset[str]
 predicate filterFileWise(Element node, string str)
 {
     node.getLocation().getFile().getBaseName().regexpMatch(str + ".cs")
 }
 
 predicate filterNameSpaceWise(Element node, string str)
 {
     exists(Namespace ns | ns.hasName(str) and ns.getFile() = node.getLocation().getFile())
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 //------------------------Read Annotations from External File---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 // Run the query in a terminal (available in VS Code) using the below command:
 // Usage: $codeql database analyze <database-dir> --format=csv --output=<file-name> resourceLeakAnalysisWithAnnotationsInCode.ql
 // file.csv has annotations that are added manually to the file. 
 // Each row contains comma-separated 5 columns which forms the arguments of the external predicate readAnnotation.
 
// predicate readAnnotation(string filename, string lineNumber, string programElementType, string programElementName, string annotation)
// {
// }
 
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

from Element e, string str
where  str = mayNotBeDisposedAlt(e) // actual analysis
       // and not suppressAlerts(src) 
        // and filterFileWise(e, "")
select e, str

// from DataFlow::Node src
// where   isSource(src) and not isInMockOrTestFile(src) and checkForResourceType(src.getType())
// select src