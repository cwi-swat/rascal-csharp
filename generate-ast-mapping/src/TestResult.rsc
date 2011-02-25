module TestResult

public alias CSharpFile=list[AstNode];
data AstNode = comment(CommentType commentType, str content, bool startsLine)
  |  namespaceDeclaration(str name, list[AstNode] identifiers, list[AstNode] members, str name)
  |  constraint(list[AstType] baseTypes, str typeParameter)
  |  attribute(list[Expression] arguments)
  |  queryOrdering(QueryOrderingDirection direction, Expression expression)
  |  cSharpModifierToken(list[Modifiers] allModifiers, list[Modifiers] modifier)
  |  variablePlaceholder(str name, str name)
  |  usingDeclaration(str namespace)
  |  cSharpTokenNode()
  |  parameterDeclaration(str name, Expression defaultExpression, str name, ParameterModifier parameterModifier)
  |  switchSection(list[AstNode] caseLabels, list[Statement] statements)
  |  usingAliasDeclaration(str \alias)
  |  typeParameterDeclaration(str name, VarianceModifier variance)
  |  catchClause(Statement body, str variableName)
  |  identifier(str name)
  |  attributeSection(AttributeTarget attributeTarget, list[AstNode] attributes)
  |  constructorInitializer(list[Expression] arguments, ConstructorInitializerType constructorInitializerType)
  |  compilationUnit()
  |  variableInitializer(str name, str name)
  |  arraySpecifier(int dimensions)
  |  caseLabel(Expression expression)
  |  statement(Statement nodeStatement)
  |  astType(AstType nodeAstType)
  |  attributedNode(AttributedNode nodeAttributedNode)
  |  expression(Expression nodeExpression)
  |  queryClause(QueryClause nodeQueryClause);

data QueryClause = queryContinuationClause(str identifier, Expression precedingQuery)
  |  queryWhereClause(Expression condition)
  |  queryGroupClause(Expression key, Expression projection)
  |  queryOrderClause(list[AstNode] orderings)
  |  querySelectClause(Expression expression)
  |  queryLetClause(Expression expression, str identifier)
  |  queryFromClause(Expression expression, str identifier)
  |  queryJoinClause(Expression equalsExpression, Expression inExpression, str intoIdentifier, bool isGroupJoin, str joinIdentifier, Expression onExpression);

data Expression = lambdaExpression(AstNode body, list[AstNode] parameters)
  |  conditionalExpression(Expression condition, Expression falseExpression, Expression trueExpression)
  |  binaryOperatorExpression(Expression left, BinaryOperatorType operator, Expression right)
  |  directionExpression(Expression expression, FieldDirection fieldDirection)
  |  castExpression(Expression expression)
  |  indexerExpression(list[Expression] arguments, Expression target)
  |  parenthesizedExpression(Expression expression)
  |  baseReferenceExpression()
  |  sizeOfExpression()
  |  arrayCreateExpression(list[AstNode] additionalArraySpecifiers, list[Expression] arguments, Expression initializer)
  |  unaryOperatorExpression(Expression expression, UnaryOperatorType operator)
  |  asExpression(Expression expression)
  |  typeReferenceExpression()
  |  typeOfExpression()
  |  defaultValueExpression()
  |  anonymousMethodExpression(Statement body, bool hasParameterList, list[AstNode] parameters)
  |  uncheckedExpression(Expression expression)
  |  isExpression(Expression expression)
  |  identifierExpression(str identifier, list[AstType] typeArguments)
  |  checkedExpression(Expression expression)
  |  primitiveExpression(value \value)
  |  expressionPlaceholder()
  |  objectCreateExpression(list[Expression] arguments, Expression initializer)
  |  namedArgumentExpression(Expression expression, str identifier)
  |  argListExpression(list[Expression] arguments, bool isAccess)
  |  memberReferenceExpression(str memberName, Expression target, list[AstType] typeArguments)
  |  invocationExpression(list[Expression] arguments, Expression target)
  |  pointerReferenceExpression(str memberName, Expression target, list[AstType] typeArguments)
  |  assignmentExpression(Expression left, AssignmentOperatorType operator, Expression right)
  |  thisReferenceExpression()
  |  stackAllocExpression(Expression countExpression)
  |  arrayInitializerExpression(list[Expression] elements)
  |  queryExpression(list[QueryClause] clauses);

data AttributedNode = enumMemberDeclaration(str name, Expression initializer, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name)
  |  accessor(list[AstNode] attributes, Statement body, list[AstNode] modifierTokens, list[Modifiers] modifiers)
  |  delegateDeclaration(str name, list[AstNode] constraints, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] parameters, list[AstNode] typeParameters)
  |  destructorDeclaration(str name, Statement body, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name)
  |  typeDeclaration(str name, list[AstType] baseTypes, ClassType classType, list[AstNode] constraints, list[AttributedNode] members, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] typeParameters)
  |  constructorDeclaration(str name, Statement body, AstNode initializer, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] parameters)
  |  memberDeclaration(MemberDeclaration nodeMemberDeclaration);

data MemberDeclaration = indexerDeclaration(str name, AttributedNode getter, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] parameters, AttributedNode setter)
  |  methodDeclaration(str name, Statement body, list[AstNode] constraints, bool isExtensionMethod, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] parameters, list[AstNode] typeParameters)
  |  operatorDeclaration(str name, Statement body, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, OperatorType operatorType, list[AstNode] parameters)
  |  propertyDeclaration(str name, AttributedNode getter, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, AttributedNode setter)
  |  customEventDeclaration(str name, list[AstNode] attributes, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, AttributedNode removeAccessor)
  |  fieldDeclaration(str name, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] variables)
  |  eventDeclaration(str name, list[AstNode] modifierTokens, list[Modifiers] modifiers, str name, list[AstNode] variables);

data AstType = simpleType(str identifier, list[AstType] typeArguments)
  |  composedType(list[AstNode] arraySpecifiers, bool hasNullableSpecifier, int pointerRank)
  |  typePlaceholder()
  |  memberType(bool isDoubleColon, str memberName, list[AstType] typeArguments)
  |  primitiveType(str keyword);

data Statement = returnStatement(Expression expression)
  |  whileStatement(Expression condition, Statement embeddedStatement)
  |  yieldBreakStatement()
  |  blockStatementPlaceholder(list[Statement] statements)
  |  gotoCaseStatement(Expression labelExpression)
  |  fixedStatement(Statement embeddedStatement, list[AstNode] variables)
  |  labelStatement(str label)
  |  switchStatement(Expression expression, list[AstNode] switchSections)
  |  ifElseStatement(Expression condition, Statement falseStatement, Statement trueStatement)
  |  expressionStatement(Expression expression)
  |  gotoDefaultStatement()
  |  variableDeclarationStatement(list[Modifiers] modifiers, list[AstNode] variables)
  |  breakStatement()
  |  tryCatchStatement(list[AstNode] catchClauses, Statement finallyBlock, Statement tryBlock)
  |  gotoStatement(str label)
  |  usingStatement(Statement embeddedStatement, AstNode resourceAcquisition)
  |  throwStatement(Expression expression)
  |  unsafeStatement(Statement body)
  |  doWhileStatement(Expression condition, Statement embeddedStatement)
  |  continueStatement()
  |  checkedStatement(Statement body)
  |  statementPlaceholder()
  |  forStatement(Expression condition, Statement embeddedStatement, list[Statement] initializers, list[Statement] iterators)
  |  foreachStatement(Statement embeddedStatement, Expression inExpression, str variableName)
  |  lockStatement(Statement embeddedStatement, Expression expression)
  |  blockStatement(list[Statement] statements)
  |  emptyStatement()
  |  yieldStatement(Expression expression)
  |  uncheckedStatement(Statement body);

data ConstructorInitializerType = base()
  |  this();

data ParameterModifier = none()
  |  ref()
  |  out()
  |  params()
  |  this();

data QueryOrderingDirection = none()
  |  ascending()
  |  descending();

data UnaryOperatorType = not()
  |  bitNot()
  |  minus()
  |  plus()
  |  increment()
  |  decrement()
  |  postIncrement()
  |  postDecrement()
  |  dereference()
  |  addressOf();

data FieldDirection = none()
  |  out()
  |  ref();

data BinaryOperatorType = bitwiseAnd()
  |  bitwiseOr()
  |  conditionalAnd()
  |  conditionalOr()
  |  exclusiveOr()
  |  greaterThan()
  |  greaterThanOrEqual()
  |  equality()
  |  inEquality()
  |  lessThan()
  |  lessThanOrEqual()
  |  add()
  |  subtract()
  |  multiply()
  |  divide()
  |  modulus()
  |  shiftLeft()
  |  shiftRight()
  |  nullCoalescing()
  |  \any();

data AssignmentOperatorType = assign()
  |  add()
  |  subtract()
  |  multiply()
  |  divide()
  |  modulus()
  |  shiftLeft()
  |  shiftRight()
  |  bitwiseAnd()
  |  bitwiseOr()
  |  exclusiveOr()
  |  \any();

data ClassType = class()
  |  enum()
  |  interface()
  |  struct()
  |  delegate()
  |  \module();

data Modifiers = none()
  |  \private()
  |  internal()
  |  protected()
  |  \public()
  |  abstract()
  |  virtual()
  |  sealed()
  |  static()
  |  override()
  |  readonly()
  |  const()
  |  new()
  |  partial()
  |  extern()
  |  volatile()
  |  unsafe()
  |  fixed()
  |  visibilityMask();

data CommentType = singleLine()
  |  multiLine()
  |  documentation();

data OperatorType = logicalNot()
  |  onesComplement()
  |  increment()
  |  decrement()
  |  \true()
  |  \false()
  |  addition()
  |  subtraction()
  |  unaryPlus()
  |  unaryNegation()
  |  multiply()
  |  division()
  |  modulus()
  |  bitwiseAnd()
  |  bitwiseOr()
  |  exclusiveOr()
  |  leftShift()
  |  rightShift()
  |  equality()
  |  inequality()
  |  greaterThan()
  |  lessThan()
  |  greaterThanOrEqual()
  |  lessThanOrEqual()
  |  implicit()
  |  explicit();

data AttributeTarget = none()
  |  assembly()
  |  \module()
  |  \return()
  |  param()
  |  field()
  |  \return()
  |  method()
  |  unknown();

data VarianceModifier = invariant()
  |  covariant()
  |  contravariant();