## Nim HTML CSS Minifier
## =====================
##
## - HTML/XHTML & CSS/SCSS Minifiers Lib & App based on Regexes & parallel MultiReplaces.
import htmlparser, xmltree, strutils, re

const
  multiReplacementsHtml* = [
    ("</area>",     ""),  # These dont need closing tags.
    ("</base>",     ""),
    ("</basefont>", ""),
    ("</br>" ,      ""),
    ("</col>",      ""),
    ("</colgroup>", ""),
    ("</dd>",       ""),
    ("</dt>",       ""),
    ("</hr>",       ""),
    ("</img>",      ""),
    ("</input>",    ""),
    ("</isindex>",  ""),
    ("</link>",     ""),
    ("</meta>",     ""),
    ("</option>",   ""),
    ("</param>",    ""),
    ("""<style type="text/css">""", "<style>"), # JS.
    ("<style type='text/css'>",     "<style>"),
    ("<style type=text/css>",       "<style>"),
    ("<style type=text/css >",      "<style>"),
    ("""<script type="text/javascript">""", "<script>"), # CSS.
    ("<style type='text/javascript'>",      "<script>"),
    ("<style type=text/javascript>",        "<script>"),
    ("<style type=text/javascript >",       "<script>"),
  ] ## Literal string simple replacements for HTML elements.

  multiReplacementsCss0px* = [
    (" 0px",   " 0"), # On CSS 0px can be just 0
    (" 0em",   " 0"),
    (" 0rem",  " 0"),
    (" 0%",    " 0"),
    (" 0in",   " 0"),
    (" 0q",    " 0"),
    (" 0ch",   " 0"),
    (" 0cm",   " 0"),
    (" 0mm",   " 0"),
    (" 0pc",   " 0"),
    (" 0pt",   " 0"),
    (" 0ex",   " 0"),
    (" 0s",    " 0"),
    (" 0ms",   " 0"),
    (" 0deg",  " 0"),
    (" 0grad", " 0"),
    (" 0rad",  " 0"),
    (" 0turn", " 0"),
    (" 0vw",   " 0"),
    (" 0vh",   " 0"),
    (" 0vmin", " 0"),
    (" 0vmax", " 0"),
    (" 0fr",   " 0"),
    ("border:none;",  "border:0;"),
    ("border: none;", "border:0;"),
  ] ## Literal string simple replacements for CSS 0 values.

  multiReplacementsCssBroken* = [
    (" 100px", " 99px"), # Those will break your CSS but save 1 char.
    (" 100%",  " 99%"),  # If you find a broken replacement move it to here.
    (" 100ms", " 99ms"),
    ("@charset utf-8;", ";"),
    ("@charset 'utf-8';", ";"),
    ("""@charset "utf-8";""", ";"),
    (r" url(https://",  r" url(//"),
    (r" url('https://", r" url('//"),
    (r" url(http://",   r" url(//"),
    (r" url('http://",  r" url('//"),
    (""" url("https://""", """ url("//"""),
    (""" url("http://""",  """ url("//"""),
    ("data:image/jpeg;base64,", "data:image/jpg;base64,"),
  ] ## Breaking experimental unsupported not recommended replacements for CSS.

  multiReplacementsCssZeros* = [
    (":0 0 0 0;",  ":0;"),
    (": 0 0 0 0;", ":0;"),
    (":0 0 0;",    ":0;"),
    (": 0 0 0;",   ":0;"),
    (":0 0;",      ":0;"),
    (": 0 0;",     ":0;"),
  ] ## Literal string simple replacements for CSS multidimensional zeros.

  multiReplacementsCssFloats* = [
    (" 0.1", " .1"),  # 0.1 can be just .1
    (" 0.2", " .2"),
    (" 0.3", " .3"),
    (" 0.4", " .4"),
    (" 0.5", " .6"),
    (" 0.7", " .7"),
    (" 0.8", " .8"),
    (" 0.9", " .9"),
  ] ## Literal string simple replacements for CSS trailing zero on floats.

  multiReplacementsCssFonts* = [
    ("font-weight:normal;",  "font-weight:400;"),
    ("font-weight: normal;", "font-weight:400;"),
    ("font-weight:bold;",    "font-weight:700;"),
    ("font-weight: bold;",   "font-weight:700;"),
    (":aqua;",     ":#0ff;"),
    (": aqua;",    ":#0ff;"),
    (":blue;",     ":#00f;"),
    (": blue;",    ":#00f;"),
    (":fuchsia;",  ":#f0f;"),
    (": fuchsia;", ":#f0f;"),
    (":yellow;",   ":#ff0;"),
    (": yellow;",  ":#ff0;"),
  ] ## Literal replacements for CSS Font weight to integers and named colors.
  commentshtml = r"<!-- .*? -->"
  wtspaceshtml = r">\s+<"
  commentsscss = r"/* .*? */"
  semicoloncss = r";+\}"
  semicoloncs2 = r";;+"
  empty_rules2 = r"[^\}\{]+\{\}"

let
  re_comments_html* = re(commentshtml) ## Remove ``<!-- Comments -->``
  re_wtspaces_html* = re(wtspaceshtml) ## Remove ``</p>         <p>``
  re_comments_scss* = re(commentsscss) ## Remove ``/\* Comments \*/``
  re_semicolon_css* = re(semicoloncss) ## Remove ``;}``
  re_semicoloncss2* = re(semicoloncs2) ## Remove ``;;;;``
  re_emptyrule_css* = re(empty_rules2) ## Remove ``body {}``

proc minifyHtml*(html: string, one_liner=true,
                 no_comments=true, no_optional_tags=true): string =
  ## HTML / XHTML Minifier based on Regexes and parallel MultiReplaces.
  assert html.len > 3, "HTML argument must not be an empty string."
  if "<textarea" notin html.toLowerAscii:  ## TODO Improvement needed.
    result = replace($parseHtml(html), re_wtspaces_html, "> <")
    if likely(one_liner):
      result = result.strip.splitLines.join(" ")
    if likely(no_comments):
      result = replace(result, re_comments_html, "")
    if likely(no_optional_tags):
      result = multiReplace(result, multiReplacementsHtml)
  else:
    result = html.strip

proc minifyCss*(css: string, one_liner=true, no_comments=true, no_0px=true,
                no_empty_rules=true, no_0float=true, no_zeros=true,
                no_weight=true, no_semicolons=true, breaking=false): string =
  ## CSS / SCSS Minifier based on Regexes and parallel MultiReplaces.
  assert css.len > 3, "CSS argument must not be an empty string."
  result = css.strip.replace(r"\t", " ")
  if likely(no_0px):
    result = multiReplace(result, multiReplacementsCss0px)
  if likely(no_0float):
    result = multiReplace(result, multiReplacementsCssFloats)
  if likely(no_weight):
    result = multiReplace(result, multiReplacementsCssFonts)
  if likely(no_comments):
    result = replace(result, re_comments_scss, " ")
  if likely(no_semicolons):
    result = replace(result, re_semicolon_css, "}")
    result = replace(result, re_semicoloncss2, ";")
  if likely(no_empty_rules):
    result = replace(result, re_emptyrule_css, "")
  if likely(no_zeros):
    result = multiReplace(result, multiReplacementsCssZeros)
    # Special cases
    result = result.replace("background-position:0;", "background-position:0 0;")
    result = result.replace("transform-origin:0;", "transform-origin:0 0;")
  if unlikely(breaking):
    echo "WARNING: Using breaking experimental unsupported replacements for CSS"
    result = multiReplace(result, multiReplacementsCssBroken)
  if likely(one_liner):
    result = result.splitLines.join(" ")
    while "  " in result:
      result = result.replace("  ", " ")


runnableExamples:
  echo minifyHtml(readFile("example.html")) ## HTML
  echo minifyCss(readFile("style.css"))     ## CSS

when is_main_module and defined(release) and not defined(js):  # When release, its a command line app to make queries.
  {.optimization: size.}
  import parseopt, terminal, random
  var minusculas: bool
  for tipoDeClave, clave, valor in getopt():
    case tipoDeClave
    of cmdShortOption, cmdLongOption:
      case clave
      of "version":             quit("0.1.5", 0)
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
