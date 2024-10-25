# teXdoc_test  <-function (sources, exo = c(), base.path = "src/model", out = "doc", 
#           out.path = getwd(), compile_pdf = TRUE) 
# {
#   out <- basename(out)
#   peg <- pegr::new.parser()
#   buildCall <- function(name, params) {
#     params <- if (is.list(params)) {
#       stringr::str_c(params, collapse = ", ")
#     }
#     else {
#       params
#     }
#     stringr::str_c(name, "(", params, ")", collapse = "")
#   }
#   str_merge <- function(v, char = "") stringr::str_c(v, collapse = char)
#   buildString <- function(v) stringr::str_c("\"", str_merge(v), 
#                                             "\"")
#   dynIndices <- function(x) attr(x, "indices")
#   dynTimeIndex <- function(x) attr(x, "timeIndex")
#   dynWhere <- function(x) attr(x, "where")
#   dynCondition <- function(x) attr(x, "condition")
#   dynParentheses <- function(x) attr(x, "parentheses")
#   dynIdentity <- function(...) list(...)
#   custom <- list(dynName = dynIdentity, dynNum = dynIdentity, 
#                  dynVar = dynIdentity, dynExp = dynIdentity, dynFun = dynIdentity, 
#                  dynOp = dynIdentity, dynEq = dynIdentity)
#   dynName <- function(s) {
#     custom$dynName(s)
#   }
#   dynNum <- function(val) {
#     x <- as.numeric(val)
#     attr(x, "indices") <- NULL
#     class(x) <- c(class(x), "dynNum")
#     custom$dynNum(x)
#   }
#   dynVar <- function(name) dynVarGen(name)
#   dynVarTime <- function(name, timeIndex) dynVarGen(name, 
#                                                     timeIndex = timeIndex)
#   dynVarIndex <- function(name, indices) dynVarGen(name, indices)
#   dynVarIndexTime <- function(name, indices, timeIndex) dynVarGen(name, 
#                                                                   indices, timeIndex)
#   dynVarGen <- function(name, indices = NULL, timeIndex = NULL) {
#     attr(name, "indices") <- indices
#     attr(name, "timeIndex") <- timeIndex
#     class(name) <- c(class(name), "dynVar")
#     custom$dynVar(name, indices, timeIndex)
#   }
#   dynExpParen <- function(lst) dynExpGen(lst, parentheses = TRUE)
#   dynExpUnary <- function(op, lst) dynOp(op, dynZero, lst)
#   dynExpBinary <- function(lhs, op, rhs) dynOp(op, lhs, rhs)
#   dynExpIf <- function(lst, condition) dynExpGen(lst, condition = condition)
#   dynExpWhere <- function(lst, where) dynExpGen(lst, where = where)
#   dynExpIfWhere <- function(lst, condition, where) dynExpGen(lst, 
#                                                              condition = condition, where = where)
#   dynExpGen <- function(lst, indices = NULL, where = NULL, 
#                         condition = NULL, parentheses = FALSE) {
#     attr(lst, "indices") <- c(dynIndices(lst), indices)
#     attr(lst, "where") <- if (!is.null(where)) {
#       attr(lst, "indices") <- setdiff(attr(lst, "indices"), 
#                                       where)
#       where
#     }
#     else {
#       NULL
#     }
#     attr(lst, "condition") <- if (is.null(condition)) {
#       dynCondition(condition)
#     }
#     else {
#       condition
#     }
#     attr(lst, "parentheses") <- parentheses
#     class(lst) <- c(class(lst), "dynExp")
#     custom$dynExp(lst, indices, where, condition, parentheses)
#   }
#   dynFun <- function(name, .args) {
#     attr(name, "args") <- .args
#     attr(name, "indices") <- Reduce(c, lapply(.args, dynIndices), 
#                                     c())
#     class(name) <- c(class(name), "dynFun")
#     custom$dynFun(name, .args)
#   }
#   dynOp <- function(op, e1, e2) {
#     dynExpGen(custom$dynOp(op, e1, e2), c(dynIndices(e1), 
#                                           dynIndices(e2)) %>% unique)
#   }
#   dynEq <- function(lhs, rhs, isOver = FALSE) {
#     eq <- list(lhs = lhs, rhs = rhs)
#     class(eq) <- c(class(eq), "dynEq")
#     custom$dynEq(lhs, rhs)
#   }
#   dynZero <- dynNum(0)
#   peg <- peg %>% pegr::add_rule("Space <- ('\t' / ' ')+", 
#                                 act = "list()") %>% pegr::add_rule("Comma <- Space* ',' Space*", 
#                                                                    act = "list()") %>% pegr::add_rule("Equal <- Space* '=' Space*", 
#                                                                                                       act = "list()") %>% pegr::add_rule("Different <- '<>'", 
#                                                                                                                                          act = "'!='") %>% pegr::add_rule("Division <- '/'", 
#                                                                                                                                                                           act = "buildString(v)") %>% pegr::add_rule("LBracket <- '[' Space*", 
#                                                                                                                                                                                                                      act = "list()") %>% pegr::add_rule("RBracket <- Space* ']'", 
#                                                                                                                                                                                                                                                         act = "list()") %>% pegr::add_rule("LParen <- '(' Space*", 
#                                                                                                                                                                                                                                                                                            act = "list()") %>% pegr::add_rule("RParen <- Space* ')'", 
#                                                                                                                                                                                                                                                                                                                               act = "list()") %>% pegr::add_rule("LCurly <- '{' Space*", 
#                                                                                                                                                                                                                                                                                                                                                                  act = "list()") %>% pegr::add_rule("RCurly <- Space* '}'", 
#                                                                                                                                                                                                                                                                                                                                                                                                     act = "list()") %>% pegr::add_rule("Operator <- Space* ('<=' / '>=' / Different / '<' / '>' / '+' / '-' / '/' / '*' / '^') Space*", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                        act = "buildString(v)") %>% pegr::add_rule("Name <- ([a-z] / [A-Z] / '_' / '@' / '%') ([0-9] / [a-z] / [A-Z] / '_')*", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   act = "buildCall('dynName', buildString(v))") %>% pegr::add_rule("Index <- LBracket (Name Comma)* Name RBracket", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    act = "buildCall('c', v)") %>% pegr::add_rule("TimeIndex <- LCurly '-1' RCurly", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  act = "\"\\\"t-1\\\"\"") %>% pegr::add_rule("VariableSimple <- Name", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              act = "buildCall('dynVar', v)") %>% pegr::add_rule("VariableIndex <- Name Index", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 act = "buildCall('dynVarIndex', v)") %>% pegr::add_rule("VariableTime <- Name TimeIndex", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         act = "buildCall('dynVarTime', v)") %>% pegr::add_rule("VariableIndexTime <- Name Index TimeIndex", 
#                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                act = "buildCall('dynVarIndexTime', v)") %>% pegr::add_rule("Variable <- VariableIndexTime / VariableIndex / VariableTime / VariableSimple") %>% 
#     pegr::add_rule("Number <- [0-9]+ / ([0-9]+)? '.' [0-9]+", 
#                    act = "buildCall('dynNum', buildString(v))") %>% 
#     pegr::add_rule("Function <- Name LParen QualifiedExpression? (Comma Expression)* RParen", 
#                    act = "buildCall('dynFun', v)") %>% pegr::add_rule("Term <- Function / Variable / Number") %>% 
#     pegr::add_rule("Fraction <- LParen Expression RParen Space* Division Space* LParen Expression RParen", 
#                    act = "buildCall('dynExpBinary', v)") %>% pegr::add_rule("ParenExp <- LParen Expression RParen", 
#                                                                             act = "buildCall('dynExpParen', v)") %>% pegr::add_rule("UnaryExp <- Operator Space* Expression", 
#                                                                                                                                     act = "buildCall('dynExpUnary', v)") %>% pegr::add_rule("BinaryExp <- Term Operator Expression", 
#                                                                                                                                                                                             act = "buildCall('dynExpBinary', v)") %>% pegr::add_rule("BinaryExpParen <- ParenExp Operator Expression", 
#                                                                                                                                                                                                                                                      act = "buildCall('dynExpBinary', v)") %>% pegr::add_rule("Expression <- Fraction / BinaryExpParen / ParenExp / BinaryExp / UnaryExp / Term") %>% 
#     pegr::add_rule("IfKeyword <-  Space+ 'if' Space+", act = "list()") %>% 
#     pegr::add_rule("WhereKeyword <-  Space+ ('where' / 'on') Space+", 
#                    act = "list()") %>% pegr::add_rule("If <- IfKeyword Expression") %>% 
#     pegr::add_rule("Where <- WhereKeyword Name (Space+ 'in' Space+ Name)?") %>% 
#     pegr::add_rule("ExpressionIf <- Expression If", act = "buildCall('dynExpIf', v)") %>% 
#     pegr::add_rule("ExpressionWhere <- Expression Where", 
#                    act = "buildCall('dynExpWhere', v)") %>% pegr::add_rule("ExpressionIfWhere <- Expression If Where", 
#                                                                            act = "buildCall('dynExpIfWhere', v)") %>% pegr::add_rule("QualifiedExpression <- ExpressionIfWhere / ExpressionWhere / ExpressionIf / Expression") %>% 
#     pegr::add_rule("OverKeyword <- '@over'", act = "list()") %>% 
#     pegr::add_rule("RawEquation <- Expression Equal QualifiedExpression", 
#                    act = "buildCall('dynEq', v)") %>% pegr::add_rule("Equation <- OverKeyword Space+ RawEquation / RawEquation")
#   nameSplit <- function(s) {
#     if ((s != "t_0") & stringr::str_detect(s, "_")) {
#       chunks <- s %>% stringr::str_split("_") %>% unlist
#       stringr::str_c(chunks[1], "^{", stringr::str_c(tail(chunks, 
#                                                           -1), collapse = ","), "}")
#     }
#     else {
#       s
#     }
#   }
#   latex <- list(dynName = function(s) {
#     s %>% stringr::str_replace("^(ES|es|Es|eS)_(.*)", "\\\\eta^{\\2}") %>% 
#       stringr::str_replace("^(p|P)hi_(.*)", "\\\\varphi^{\\2}") %>% 
#       stringr::str_replace("^(p|P)hi$", "\\\\varphi") %>% 
#       stringr::str_replace("^(p|P)hi(.*)", "\\\\varphi^{\\2}") %>% 
#       stringr::str_replace("^RHO(.*)", "\\\\rho\\1") %>% 
#       stringr::str_replace("^rho(.*)", "\\\\rho\\1") %>% 
#       stringr::str_replace("^ADJUST([0-9])", "\\\\alpha_{\\1}") %>% 
#       stringr::str_replace("^ADJUST", "\\\\alpha") %>% 
#       stringr::str_replace("MARKUP", "\\\\mu") %>% stringr::str_replace("Rdep", 
#                                                                         "\\\\delta") %>% stringr::str_replace("delta", "\\\\delta") %>% 
#       stringr::str_replace("tau", "\\\\tau") %>% stringr::str_replace("sigma", 
#                                                                       "\\\\sigma") %>% stringr::str_replace("^rho(.*)", 
#                                                                                                             "\\\\rho") %>% stringr::str_replace("^eta(.*)", 
#                                                                                                                                                 "\\\\zeta") %>% stringr::str_replace("^sigma(.*)", 
#                                                                                                                                                                                      "\\\\sigma^{\\1}") %>% stringr::str_replace("^nu(.*)", 
#                                                                                                                                                                                                                                  "\\\\nu^{\\1}") %>% stringr::str_replace("theta_(.*)", 
#                                                                                                                                                                                                                                                                           "\\\\theta^{\\1}") %>% stringr::str_replace("bis$", 
#                                                                                                                                                                                                                                                                                                                       "_bis") %>% stringr::str_replace("ter$", "_ter") %>% 
#       stringr::str_replace("@year", "t") %>% stringr::str_replace("%baseyear", 
#                                                                   "t_0") %>% stringr::str_replace("^@pchy(.*)", "g^{\\1}") %>% 
#       stringr::str_replace("^GR_(.*)", "g^{\\1}") %>% 
#       stringr::str_replace("^(.*)^2", "{\\1}^{2}") %>% 
#       stringr::str_replace("%", "\\\\%") %>% nameSplit()
#   }, dynNum = function(x) x, dynVar = function(name, indices = NULL, 
#                                                timeIndex = NULL) {
#     if (is.null(indices) & is.null(timeIndex)) name else stringr::str_c(name, 
#                                                                         "_{", stringr::str_c(c(indices, timeIndex), collapse = ", "), 
#                                                                         "}")
#   }, dynExp = function(lst, indices, where, condition, parentheses) {
#     if (parentheses) {
#       stringr::str_c("\\left( ", lst, " \\right)")
#     } else {
#       lst
#     }
#   }, dynFun = function(name, ...) {
#     .args <- list(...)
#     if (name == "sum") {
#       stringr::str_c("\\sum_{", stringr::str_c(dynWhere(.args[[1]]), 
#                                                collapse = ", "), "} ", .args[[1]])
#     } else if (name == "d") {
#       stringr::str_c("\\varDelta \\left(", .args[[1]], 
#                      "\\right)")
#     } else if (name == "exp") {
#       stringr::str_c("e^{", .args[[1]], "}")
#     } else if (name == "@elem") {
#       if (stringr::str_detect(.args[[1]], ", t-1\\}")) {
#         stringr::str_replace(.args[[1]], ", t-1\\}", 
#                              ", t_{0}-1}")
#       } else if (.args[[2]] == "t_0") {
#         if (stringr::str_sub(.args[[1]], -1, -1) == 
#             "}") {
#           stringr::str_c(stringr::str_sub(.args[[1]], 
#                                           1, -2), ", t_0}")
#         } else {
#           stringr::str_c(.args[[1]], "_{t_0}")
#         }
#       } else {
#         stringr::str_replace(.args[[1]], "\\}$", ", t_{0}}")
#       }
#     } else {
#       stringr::str_c("\\operatorname{", name, "} ", ifelse(stringr::str_detect(.args, 
#                                                                                " \\+ | - | \\* | / | \\. |\\\\;"), stringr::str_c("\\left(", 
#                                                                                                                                   .args, "\\right)"), .args))
#     }
#   }, dynOp = function(op, e1, e2) {
#     if (e1 == "0") {
#       stringr::str_c(op, e2)
#     } else if (op == "/") {
#       stringr::str_c("\\frac{", e1, "}{", e2, "}")
#     } else if ((op == "*") & (!stringr::str_detect(e1, "_\\{"))) {
#       stringr::str_c(e1, " . ", e2)
#     } else if (op == "^") {
#       stringr::str_c(e1, " ^ {", e2, "}")
#     } else {
#       stringr::str_c(e1, " ", ifelse(op == "*", "\\;", 
#                                      op), " ", e2)
#     }
#   }, dynEq = function(lhs, rhs) {
#     eq <- stringr::str_c(lhs, " = ", rhs) %>% stringr::str_replace(" *(.*) *= *\\\\left\\( *t > t_0 *\\\\right\\) *\\. *\\\\left\\( *(.*) *\\\\right\\) *\\+.*", 
#                                                                    "\\1 = \\2")
#     stringr::str_c("\\repeatablebody{", currentFile, currentVar, 
#                    "}{", eq, "}\n")
#   })
#   custom <- latex
#   currentFile <- ""
#   currentVar <- ""
#   texHeader <- function(out) {
#     stringr::str_c("\\ifx\\fulldoc\\undefined\n\n    \\documentclass[12pt]{article}\n    \\usepackage{amsmath}\n    \\usepackage{breqn}\n    \\numberwithin{equation}{section}\n    \\usepackage{longtable}\n    \\usepackage{booktabs}\n    \\usepackage{array}\n    \\usepackage{ragged2e}\n    \\usepackage{import}\n    \\usepackage{accents}\n\n    \\makeatletter\n    \\newcommand{\\repeatablebody}[2]{\n    \\global\\@namedef{repeatable@#1}{#2}\n    }\n    \\newcommand{\\repeatable}[1]{\n    \\begin{dmath}\n    \\label{#1} \\@nameuse{repeatable@#1}\n    \\end{dmath}\n    }\n    \\newcommand{\\eqrepeat}[1]{%\n    \\@ifundefined{repeatable@#1}{NOT FOUND}{\n    \\begin{dmath}[number=\\ref{#1}]\n    \\@nameuse{repeatable@#1}\n    \\end{dmath}\n    }\n    }\n    \\makeatother\n\n    \\begin{document}\n    ", 
#                    "\\import{./}{", out, "_preface.tex}", "\n    \\fi\n    ")
#   }
#   texFooter <- "\n  \\ifx\\fulldoc\\undefined\n  \\end{document}\n  \\fi"
#   writeFile <- function(s, filename) {
#     fileConn <- file(filename)
#     writeLines(s, fileConn)
#     close(fileConn)
#   }
#   dependentVar <- function(eq) {
#     terms <- stringr::str_replace_all(eq, "\\(|\\)|d|log|@over", 
#                                       "") %>% stringr::str_split("\\+|\\*|-|=") %>% unlist %>% 
#       stringr::str_trim()
#     if (terms[1] == "1") 
#       terms[2]
#     else terms[1]
#   }
#   variableTeX <- function(v) {
#     over.id <- stringr::str_match(v, "\\([0-9]\\)$") %>% 
#       as.vector
#     code <- peg %>% pegr::apply_rule("Variable", v, exe = T) %>% 
#       pegr::value() %>% parse(text = .)
#     stringr::str_c("$", eval(code, latex), "$", ifelse(is.na(over.id), 
#                                                        "", stringr::str_c(" ", over.id)))
#   }
#   exoVariableTeX <- function(v) {
#     label <- stringr::str_c(currentFile, currentVar)
#     stringr::str_c("\\kern-0.23em \\noindent \\begingroup \\refstepcounter{equation} \\label{", 
#                    label, "}\\ref{", label, "}.\n          \\relpenalty=10000 \\binoppenalty=10000\n          \\ensuremath{", 
#                    stringr::str_replace_all(variableTeX(v), fixed("$"), 
#                                             ""), "}~ \\endgroup")
#   }
#   explicit <- list(PCH_HOUSENER_CES = "PCH^{HOUSENER,CES} = \\left( \\sum_{ce} \\varphi^{MCH,HOUS}_{ce, t_0} \\; {PCH^{HOUS}_{ce}} ^ {\\left( 1 - {\\sigma^{HOUS,ENER}} \\right)} \\right) ^ {\\frac{1}{1 - \\sigma^{HOUS,ENER}}}", 
#                    PCH_TRSP_CES = "PCH^{TRSP,CES} = \\left( \\sum_{chtrsp} \\varphi^{MCH,TRSP}_{chtrsp, t_0} \\; {PCH^{TRSP}_{chtrsp}} ^ {\\left( 1 - \\sigma^{CHTRSP} \\right)} \\right) ^ {\\left( \\frac{1}{\\left( 1 - \\sigma^{CHTRSP} \\right)} \\right)}", 
#                    `PCH_TRSP[auto]` = "PCH^{TRSP}_{auto} = \\left( \\frac{CH^{TRSPINV,VAL}_{t_0}}{CH^{TRSP,VAL}_{auto, t_0}} \\; {PCH^{TRSPINV}} ^ {\\left( 1 - \\sigma^{TRSP,INV,ENER} \\right)} + \\frac{CH^{TRSPENER,VAL}_{t_0}}{CH^{TRSP,VAL}_{auto, t_0}} \\; {PCH^{TRSPENER}} ^ {\\left( 1 - \\sigma^{TRSP,INV,ENER} \\right)} \\right) ^ {\\frac{1}{1 - \\sigma^{TRSP,INV,ENER}}}", 
#                    PCH_TRSPENER_CES = "PCH^{TRSPENER,CES} = \\left( \\sum_{ce} \\varphi^{MCH,TRSP}_{ce, t_0} \\; {PCH^{TRSP}_{ce}} ^ {\\left( 1 - \\sigma^{TRSP,ENER} \\right)} \\right) ^ { \\frac{1}{ 1 - \\sigma^{TRSP,ENER} }  }", 
#                    `EXP_HOUSING_Val[ecl]` = "EXP^{HOUSING,Val}_{ecl} = \\left( DEBT^{REHAB,Val}_{ecl, t-1} \\; \\left( R^{I,REHAB}_{ecl, t-1} + R^{RMBS,REHAB}_{ecl, t-1} \\right) + R^{CASH,REHAB}_{ecl} \\; PREHAB_{ecl} \\; REHAB_{ecl} + DEBT^{NewB,Val}_{ecl, t-1} \\; \\left( R^{I,NewBUIL}_{ecl, t-1} + R^{RMBS,NewBUIL}_{ecl, t-1} \\right) + R^{CASH,NewBUIL}_{ecl} \\; PNewBUIL_{ecl} \\; NewBUIL_{ecl} + PENER^{BUIL}_{ecl} \\; ENER^{BUIL}_{ecl} \\right)", 
#                    `GR_PENER_m2_e[ecl]` = "g^{PENER^{m2,e}}_{ecl}  = \\alpha^{g^{PENER,m2,e}_{1}} \\; g^{PENER^{m2}}_{ecl, t-1} + \\left( 1 - \\alpha^{g^{PENER,m2,e}_{1}} \\right) \\; g^{PENER^{m2,e}}_{ecl, t-1}", 
#                    `nu_REHAB[ecl]` = "\\nu^{^{REHAB}}_{ecl} = \\frac{\\left( \\tau^{REHAB,MAX}_{ecl} - \\tau^{REHAB,MIN}_{ecl} \\right) \\; \\sigma_{ecl} \\; Payback^{REHAB}_{ecl} \\; e^{\tau_{ecl} - \\sigma_{ecl} \\; Payback^{REHAB}_{ecl}}}{\\left( 1 + e^{\\tau_{ecl} - \\sigma_{ecl} \\; Payback^{REHAB}_{ecl}} \\right)^{2}}", 
#                    `d(innovation[ecl])` = "  \\varDelta \\left(innovation_{ecl}\\right) = \\eta^{BASS}_{ecl} \\; \\varDelta \\frac{2 \\; UC^{AUTO}_{ecl, cele}^{-\\nu^{diffusion}_{ecl}}}{2 \\; UC^{AUTO}_{ecl, cele}^{-\\nu^{diffusion}_{ecl}} +  UC^{AUTO}_{ecl, th} ^ {-\\nu^{diffusion}_{ecl}}}", 
#                    `phi_NewAUTO[ecl,cele]` = "  \\varphi^{NewAuto}_{ecl,cele} = \\varphi^{NewAuto^{n}}_{ecl,cele}", 
#                    `GR_PE_AUTO_e[ecl,cea]` = "g^{PE^{AUTO}}_{ecl, cea} =  \\alpha^{g^{PE^{AUTO,e}}_{1}} \\; g^{PE^{AUTO}_{ecl, cea, t-1}}  + \\left( 1 - \\alpha^{g^{PE^{AUTO,e}}_{1}} \\right) \\; g^{PE^{AUTO,e}_{ecl, cea, t-1}}")
#   toTeX <- function(eq) {
#     if (currentVar %in% names(explicit)) {
#       eq <- unlist(stringr::str_split(explicit[currentVar], 
#                                       " = "))
#       latex$dynEq(eq[1], eq[2])
#     }
#     else {
#       eq <- stringr::str_replace(eq, " where f in %list_F \\\\ K", 
#                                  "")
#       code <- peg %>% pegr::apply_rule("Equation", eq, 
#                                        exe = T) %>% pegr::value() %>% parse(text = .)
#       eval(code, latex)
#     }
#   }
#   glossaryTeX <- function(glossary) {
#     glossary <- glossary[order(tolower(names(glossary)))]
#     eqref <- sapply(glossary, function(x) attr(x, "eqlabel"))
#     stringr::str_c("\\newpage\n          \\section{Glossary}\n          \\small\n          \\begin{longtable}{@{}p{2.75cm}p{8.5cm}p{0.7cm}p{0.35cm}@{}} \n", 
#                    stringr::str_c(sapply(names(glossary), variableTeX), 
#                                   " & ", glossary, " & \\RaggedLeft \\ref{", eqref, 
#                                   "}, & \\RaggedLeft \\pageref{", eqref, "} \\\\", 
#                                   collapse = "\n \\midrule \n"), "\n\\end{longtable}")
#   }
#   stitchLines <- function(lines) {
#     stitched <- c()
#     to.stitch <- FALSE
#     for (l in lines) {
#       l <- stringr::str_trim(l)
#       if (to.stitch) {
#         stitched[length(stitched)] <- stringr::str_c(stitched[length(stitched)] %>% 
#                                                        stringr::str_sub(1, -2), l)
#       }
#       else {
#         stitched <- c(stitched, l)
#       }
#       to.stitch <- stringr::str_detect(l, " _$")
#     }
#     stitched
#   }
#   readFile <- function(filename) {
#     fileConn <- file(filename)
#     lines <- readLines(fileConn) %>% stitchLines
#     close(fileConn)
#     lines
#   }
#   cleanTeX <- function(s) {
#     s %>% stringr::str_replace_all(" & ", " \\\\& ")
#   }
#   codeToTeX <- function(filename, is.exo = FALSE) {
#     description <- ""
#     exo.buffer <- ""
#     currentFile <<- basename(filename)
#     readFile(filename) %>% Reduce(function(out, l) {
#       l <- stringr::str_trim(l)
#       processed <- if (stringr::str_detect(l, "^##### ")) {
#         description <<- ""
#         stringr::str_c("\n\n", "\\section{", stringr::str_replace(cleanTeX(l), 
#                                                                   "^##### ", ""), "}", "\n\n")
#       }
#       else if (stringr::str_detect(l, "^#### ")) {
#         description <<- ""
#         stringr::str_c("\n\n", "\\subsection{", stringr::str_replace(cleanTeX(l), 
#                                                                      "^#### ", ""), "}", "\n\n")
#       }
#       else if (stringr::str_detect(l, "^### ")) {
#         description <<- ""
#         stringr::str_c("\n\n", "\\subsubsection{", stringr::str_replace(cleanTeX(l), 
#                                                                         "^### ", ""), "}", "\n\n")
#       }
#       else if (l == "##") {
#         "\n\n"
#       }
#       else if (stringr::str_detect(l, "^##! ")) {
#         txt <- stringr::str_replace(cleanTeX(l), "^##! ", 
#                                     "")
#         description <<- txt
#         tmp <- stringr::str_c("\\noindent \\textbf{", 
#                               description, "} ")
#         if (is.exo) {
#           exo.buffer <<- stringr::str_c(tmp, " \\\\ \\\\[-8pt]")
#           ""
#         }
#         else {
#           tmp
#         }
#       }
#       else if (stringr::str_detect(l, "^## ")) {
#         tmp <- stringr::str_replace(cleanTeX(l), "^## ", 
#                                     "")
#         if (is.exo) {
#           exo.buffer <<- stringr::str_c(exo.buffer, 
#                                         tmp)
#           ""
#         }
#         else {
#           tmp
#         }
#       }
#       else if (!stringr::str_detect(l, "^#") & (stringr::str_length(l) > 
#                                                 0)) {
#         currentVar <<- dependentVar(l)
#         out$glossary[[currentVar]] <- description
#         description <<- ""
#         if (is.exo) {
#           stringr::str_c("\\noindent ", exoVariableTeX(l), 
#                          " -- ", exo.buffer)
#         }
#         else {
#           out$preface <- stringr::str_c(out$preface, 
#                                         toTeX(l), "\n")
#           stringr::str_c("\\repeatable{", currentFile, 
#                          currentVar, "}\n")
#         }
#       }
#       out$code <- stringr::str_c(out$code, "\n", processed)
#       out
#     }, ., list(code = "", glossary = list()))
#   }
#   exportLateX <- function(out, teXcode) {
#     filename <- file.path(stringr::str_c(out, ".tex"))
#     writeFile(stringr::str_c(texHeader(out), teXcode, texFooter), 
#               filename)
#     tools::texi2pdf(filename, clean = TRUE)
#   }
#   updateList <- function(l, ind, lNew) {
#     c(l[setdiff(names(l), ind)], lNew)
#   }
#   `%nin%` <- Negate(`%in%`)
#   combineGlossaries <- function(g, gNew, f) {
#     if (length(gNew) > 0) 
#       gNew <- lapply(names(gNew), function(n) {
#         x <- gNew[[n]]
#         attr(x, "eqlabel") <- stringr::str_c(f, n)
#         x
#       }) %>% `names<-`(names(gNew))
#     if (length(g) == 0 || length(gNew) == 0) {
#       c(g, gNew)
#     }
#     else {
#       g$.dict <- if (".dict" %nin% names(g)) 
#         c(names(g), names(gNew))
#       else c(g$.dict, names(gNew))
#       over <- intersect(names(g), names(gNew))
#       if (length(over) > 0) {
#         over.count <- table(g$.dict)[over]
#         c(g, updateList(gNew, over, gNew[over] %>% `names<-`(stringr::str_c(over, 
#                                                                             " (", over.count, ")"))))
#       }
#       else {
#         c(g, gNew)
#       }
#     }
#   }
#   cleanlatex2 <- function(latexcode) {
#     latexcode %>% stringr::str_replace_all("\\\\\\\\([A-Za-z])", 
#                                            "\\\\\\1")
#   }
#   first.exo <- FALSE
#   compiled <- Reduce(function(out, f) {
#     processed <- codeToTeX(file.path(base.path, f), is.exo = (f %in% 
#                                                                 exo))
#     out$preface <- stringr::str_c(out$preface, processed$preface)
#     out$code <- stringr::str_c(out$code, ifelse((!first.exo) & 
#                                                   (f %in% exo), "\\newpage\\section{Exogenous variables}\n", 
#                                                 ""), processed$code)
#     first.exo <- (f %in% exo)
#     out$glossary <- combineGlossaries(out$glossary, processed$glossary, 
#                                       basename(f))
#     out
#   }, c(sources, exo), list(preface = "", code = "", glossary = list()))
#   saved.compiled <<- compiled
#   compiled$glossary$.dict <- NULL
#   main_document_tex <- stringr::str_c(compiled$code, "\n", 
#                                       glossaryTeX(compiled$glossary)) %>% cleanlatex2
#   preface_tex <- compiled$preface %>% cleanlatex2
#   writeFile(preface_tex, stringr::str_c(out, "_preface.tex"))
#   files_to_move <- stringr::str_c(out, c(".tex", "_preface.tex"))
#   if (compile_pdf) {
#     exportLateX(out, main_document_tex)
#     files_to_move <- c(stringr::str_c(out, c(".pdf")), files_to_move)
#   }
#   else {
#     filename2 <- file.path(stringr::str_c(out, ".tex"))
#     writeFile(stringr::str_c(texHeader(out), main_document_tex, 
#                              texFooter), filename2)
#   }
#   if (!dir.exists(out.path)) {
#     dir.create(out.path)
#   }
#   purrr::set_names(files_to_move, file.path(out.path, files_to_move)) %>% 
#     purrr::map(function(file = .x) {
#       if (out.path != getwd()) {
#         file.copy(from = file.path(getwd(), file), to = file.path(out.path, 
#                                                                   file), overwrite = TRUE)
#         file.remove(file.path(getwd(), file))
#       }
#       else {
#         file.exists(file)
#       }
#     })
# }
