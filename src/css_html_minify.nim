## Nim HTML CSS Minifier
## =====================
##
## - HTML/XHTML & CSS/SCSS Minifiers Lib & App based on Regexes & parallel MultiReplaces.
import re
from strutils import strip, multiReplace

const
  multiReplacementsCss= [
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
    (" 0.1 ", " .1 "),  # 0.1 can be just .1
    (" 0.2 ", " .2 "),
    (" 0.3 ", " .3 "),
    (" 0.4 ", " .4 "),
    (" 0.5 ", " .6 "),
    (" 0.7 ", " .7 "),
    (" 0.8 ", " .8 "),
    (" 0.9 ", " .9 "),
    ("font-weight:normal;",  "font-weight:400;"), # Font weight to integers
    ("font-weight: normal;", "font-weight:400;"),
    ("font-weight:bold;",    "font-weight:700;"),
    ("font-weight: bold;",   "font-weight:700;"),
    (": ", ":"),
    ("; ", ";"),
    ("  ", " "),
  ] ## Literal replacements for CSS.

  commentshtml = r"(?=<!--)([\s\S]*?)-->"
  wtspaceshtml = r">\s+<"
  semicoloncss = r";\s+}"
  semicoloncs2 = r";;+"
  empty_rules2 = r"[^\}\{]+\{\}"
  reMinifyCss2 = r"(?s)\s|/\*.*?\*/"

let
  re_comments_html = re(commentshtml) ## Remove ``<!-- Comments -->``
  re_wtspaces_html = re(wtspaceshtml) ## Remove ``</p>         <p>``
  re_semicolon_css = re(semicoloncss) ## Remove ``;}``
  re_semicoloncss2 = re(semicoloncs2) ## Remove ``;;;;``
  re_emptyrule_css = re(empty_rules2) ## Remove ``body {}``
  re_minifyAll_css = re(reMinifyCss2) ## Clean out the rest of CSS.
  multiRegexCss= [
    (re_emptyrule_css, " "),
    (re_semicolon_css, "}"),
    (re_semicoloncss2, ";"),
    (re_minifyAll_css, " "),
  ]

template minifyHtml*(html: string): string =
  ## HTML / XHTML Minifier based on Regexes.
  replace(replace(html, re_comments_html, " "), re_wtspaces_html, "> <").strip

template minifyCss*(css: string): string =
  ## CSS / SCSS Minifier based on Regexes and parallel MultiReplaces.
  multiReplace(multiReplace(css, multiRegexCss), multiReplacementsCss).strip

runnableExamples:
  echo minifyHtml(readFile("example.html"))  ## HTML
  echo minifyCss(readFile("example.css"))    ## CSS


when is_main_module and defined(release) and not defined(js):  # When release, its a command line app to make queries.
  {.optimization: size.}
  import parseopt, terminal, random
  var minusculas: bool
  for tipoDeClave, clave, valor in getopt():
    case tipoDeClave
    of cmdShortOption, cmdLongOption:
      case clave
      of "version":             quit("0.2.0", 0)
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
