## Nim HTML CSS Minifier
## =====================
##
## - HTML/XHTML & CSS/SCSS Minifiers Lib & App based on Regexes & parallel MultiReplaces.
import strutils, re

const
  multiReHtml = [
    ("""<style type="text/css">""", "<style>"), # JS.
    ("<style type='text/css'>",     "<style>"),
    ("<style type=text/css>",       "<style>"),
    ("<style type=text/css >",      "<style>"),
    ("""<script type="text/javascript">""", "<script>"), # CSS.
    ("<style type='text/javascript'>",      "<script>"),
    ("<style type=text/javascript>",        "<script>"),
    ("<style type=text/javascript >",       "<script>"),
  ] ## Literal string simple replacements for HTML elements.

  multiReplacementsCss0px = [
    (" 0px ",   " 0 "), # On CSS 0px can be just 0
    (" 0em ",   " 0 "),
    (" 0rem ",  " 0 "),
    (" 0% ",    " 0 "),
    (" 0in ",   " 0 "),
    (" 0q ",    " 0 "),
    (" 0ch ",   " 0 "),
    (" 0cm ",   " 0 "),
    (" 0mm ",   " 0 "),
    (" 0pc ",   " 0 "),
    (" 0pt ",   " 0 "),
    (" 0ex ",   " 0 "),
    (" 0s ",    " 0 "),
    (" 0ms ",   " 0 "),
    (" 0deg ",  " 0 "),
    (" 0grad ", " 0 "),
    (" 0rad ",  " 0 "),
    (" 0turn ", " 0 "),
    (" 0vw ",   " 0 "),
    (" 0vh ",   " 0 "),
    (" 0vmin ", " 0 "),
    (" 0vmax ", " 0 "),
    (" 0fr ",   " 0 "),
  ] ## Literal string simple replacements for CSS 0 values.

  multiReplacementsCssFloats = [
    (" 0.1 ", " .1 "),  # 0.1 can be just .1
    (" 0.2 ", " .2 "),
    (" 0.3 ", " .3 "),
    (" 0.4 ", " .4 "),
    (" 0.5 ", " .6 "),
    (" 0.7 ", " .7 "),
    (" 0.8 ", " .8 "),
    (" 0.9 ", " .9 "),
  ] ## Literal string simple replacements for CSS trailing zero on floats.

  multiReplacementsCssFonts = [
    ("font-weight:normal;",  "font-weight:400;"),
    ("font-weight: normal;", "font-weight:400;"),
    ("font-weight:bold;",    "font-weight:700;"),
    ("font-weight: bold;",   "font-weight:700;"),
  ] ## Literal replacements for CSS Font weight to integers.

  commentshtml = r"(?=<!--)([\s\S]*?)-->"
  wtspaceshtml = r">\s+<"
  semicoloncss = r";+\}"
  semicoloncs2 = r";;+"
  empty_rules2 = r"[^\}\{]+\{\}"
  reMinifyCss2 = r"(?s)\s|/\*.*?\*/"
  reMinifyJS2a = r"(?s)\s|/\*.*?\*/|//[^\r\n]*"
  reMinifyJS3a = r"^\s+|\R\s*"

let
  re_comments_html = re(commentshtml) ## Remove ``<!-- Comments -->``
  re_wtspaces_html = re(wtspaceshtml) ## Remove ``</p>         <p>``
  re_semicolon_css = re(semicoloncss) ## Remove ``;}``
  re_semicoloncss2 = re(semicoloncs2) ## Remove ``;;;;``
  re_emptyrule_css = re(empty_rules2) ## Remove ``body {}``
  re_minifyAll_css = re(reMinifyCss2) ## Clean out the rest of CSS.
  re_minifyAll_js2 = re(reMinifyJS2a) ## Clean out the rest of JS.
  re_minifyAll_js3 = re(reMinifyJS3a) ## Clean out extra white spaces of JS.

proc minifyHtml*(html: string, experimental=false): string =
  ## HTML / XHTML Minifier based on Regexes.
  result = html
  if unlikely(experimental):
    result = replace(result, re_comments_html, " ")
    result = multiReplace(result, multiReHtml)
  result = replace(result, re_wtspaces_html, "> <").strip

proc minifyCss*(css: string, noEmptyRules=true, noXtraSemicolon=true, condenseUnits=true, experimental=false): string =
  ## CSS / SCSS Minifier based on Regexes and parallel MultiReplaces.
  result = css
  if unlikely(experimental): result = multiReplace(result, multiReplacementsCssFonts)
  if likely(condenseUnits):
    result = multiReplace(result, multiReplacementsCss0px)
    result = multiReplace(result, multiReplacementsCssFloats)
  if likely(noEmptyRules): result = replace(result, re_emptyrule_css, " ")
  result = replace(result, re_minifyAll_css, " ").strip
  if likely(noXtraSemicolon):
    result = replace(result, re_semicolon_css, "}")
    result = replace(result, re_semicoloncss2, ";")

proc minifyJs*(js: string, experimental=false): string =
  ## JS Minifier based on Regexes.
  result = js
  result = replace(result, re_minifyAll_js2, " ").strip
  if unlikely(experimental): result = replace(result, re_minifyAll_js3, " ")

runnableExamples:
  echo minifyHtml(readFile("example.html"))  ## HTML
  echo minifyCss(readFile("example.css"))    ## CSS
  echo minifyJs(readFile("example.js"))      ## JS


when is_main_module and defined(release) and not defined(js):  # When release, its a command line app to make queries.
  {.optimization: size.}
  import parseopt, terminal, random
  var minusculas: bool
  for tipoDeClave, clave, valor in getopt():
    case tipoDeClave
    of cmdShortOption, cmdLongOption:
      case clave
      of "version":             quit("0.2.0vmin", 0)
      of "license", "licencia": quit("MIT", 0)
      of "help", "ayuda":       quit("minify --color --lower index.html", 0)
      of "minusculas", "lower": minusculas = true
      of "color":
        randomize()
        setBackgroundColor(bgBlack)
        setForegroundColor([fgRed, fgGreen, fgYellow, fgBlue, fgMagenta, fgCyan, fgWhite].rand)
    of cmdArgument:
      var resultadito: string
      if clave.toLowerAscii.endswith(".html") or clave.toLowerAscii.endswith(".htm"):
        resultadito = minifyHtml(readFile(clave.string))
      elif clave.toLowerAscii.endswith(".css") or clave.toLowerAscii.endswith(".scss"):
        resultadito = minifyCss(readFile(clave.string))
      else:
        echo "Unsupported File Format. Wrong Parameters, see Help with --help"
      if minusculas: echo resultadito.toLowerAscii else: echo resultadito
    of cmdEnd: quit("Unknown Error. Wrong Parameters, see Help with --help", 1)

{.hint: "If you know Regex or Minification it needs Pull Requests to improve!".}
