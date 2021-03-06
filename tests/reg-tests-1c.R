## Regression tests for R >= 3.0.0

pdf("reg-tests-1c.pdf", encoding = "ISOLatin1.enc")

## mapply with classed objects with length method
## was not documented to work in 2.x.y
setClass("A", representation(aa = "integer"))
a <- new("A", aa = 101:106)
setMethod("length", "A", function(x) length(x@aa))
setMethod("[[", "A", function(x, i, j, ...) x@aa[[i]])
(z <- mapply(function(x, y) {x * y}, a, rep(1:3, 2)))
stopifnot(z == c(101, 204, 309, 104, 210, 318))
## reported as a bug (which it was not) by H. Pages in
## https://stat.ethz.ch/pipermail/r-devel/2012-November/065229.html

## recyling in split()
## https://stat.ethz.ch/pipermail/r-devel/2013-January/065700.html
x <- 1:6
y <- split(x, 1:2)
class(x) <- "A"
yy <- split(x, 1:2)
stopifnot(identical(y, yy))
## were different in R < 3.0.0


## dates with fractional seconds after 2038 (PR#15200)
## Extremely speculative!
z <- as.POSIXct(2^31+c(0.4, 0.8), origin=ISOdatetime(1970,1,1,0,0,0,tz="GMT"))
zz <- format(z)
stopifnot(zz[1] == zz[2])
## printed form rounded not truncated in R < 3.0.0

## origin coerced in tz and not GMT by as.POSIXct.numeric()
x <- as.POSIXct(1262304000, origin="1970-01-01", tz="EST")
y <- as.POSIXct(1262304000, origin=.POSIXct(0, "GMT"), tz="EST")
stopifnot(identical(x, y))

## Handling records with quotes in names
x <- c("a b' c",
"'d e' f g",
"h i 'j",
"k l m'")
y <- data.frame(V1 = c("a", "d e", "h"), V2 = c("b'", "f", "i"), V3 = c("c", "g", "j\nk l m"))
f <- tempfile()
writeLines(x, f)
stopifnot(identical(count.fields(f), c(3L, 3L, NA_integer_, 3L)))
stopifnot(identical(read.table(f), y))
stopifnot(identical(scan(f, ""), as.character(t(as.matrix(y)))))

## docu always said  'length 1 is sorted':
stopifnot(!is.unsorted(NA))

## str(.) for large factors should be fast:
u <- as.character(runif(1e5))
t1 <- max(0.001, system.time(str(u))[[1]]) # get a baseline > 0
uf <- factor(u)
(t2 <- system.time(str(uf))[[1]]) / t1 # typically around 1--2
stopifnot(t2  / t1 < 30)
## was around 600--850 for R <= 3.0.1


## ftable(<array with unusual dimnames>)
(m <- matrix(1:12, 3,4, dimnames=list(ROWS=paste0("row",1:3), COLS=NULL)))
ftable(m)
## failed to format (and hence print) because of NULL 'COLS' dimnames

## regression test formerly in kmeans.Rd, but result differs by platform
## Artificial example [was "infinite loop" on x86_64; PR#15364]
rr <- c(rep(-0.4, 5), rep(-0.4- 1.11e-16, 14), -.5)
r. <- signif(rr, 12)
try ( k3 <- kmeans(rr, 3, trace=2) ) ## Warning: Quick-Transfer.. steps exceed
try ( k. <- kmeans(r., 3) ) # after rounding, have only two distinct points
      k. <- kmeans(r., 2)   # fine


## regression test incorrectly in example(NA)
xx <- c(0:4)
is.na(xx) <- c(2, 4)
LL <- list(1:5, c(NA, 5:8), c("A","NA"), c("a", NA_character_))
L2 <- LL[c(1,3)]
dN <- dd <- USJudgeRatings; dN[3,6] <- NA
stopifnot(anyNA(xx), anyNA(LL), !anyNA(L2),
          anyNA(dN), !anyNA(dd), !any(is.na(dd)),
          all(c(3,6) == which(is.na(dN), arr.ind=TRUE)))

## PR#15376
stem(c(1, Inf))
## hung in 3.0.1


## PR#15377, very long variable names
x <- 1:10
y <- x + rnorm(10)
z <- y + rnorm(10)
yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy <- y
fit <- lm(cbind(yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy, z) ~ x)
## gave spurious error message in 3.0.1.

## PR#15341 singular complex matrix in rcond()
set.seed(11)
n <- 5
A <- matrix(runif(n*n),nrow=n)
B <- matrix(runif(n*n),nrow=n)
B[n,] <- (B[n-1,]+B[n-2,])/2
rcond(B)
B <- B + 0i
rcond(B)
## gave error message (OK) in R 3.0.1: now returns 0 as in real case.


## Misuse of formatC as in PR#15303
days <- as.Date(c("2012-02-02", "2012-03-03", "2012-05-05"))
(z <- formatC(days))
stopifnot(!is.object(z), is.null(oldClass(z)))
## used to copy over class in R < 3.0.2.


## PR15219
val <- sqrt(pi)
fun <- function(x) (-log(x))^(-1/2)
(res <- integrate(fun, 0, 1, rel.tol = 1e-4))
stopifnot(abs(res$value - val) < res$abs.error)
(res <- integrate(fun, 0, 1, rel.tol = 1e-6))
stopifnot(abs(res$value - val) < res$abs.error)
res <- integrate(fun, 0, 1, rel.tol = 1e-8)
stopifnot(abs(res$value - val) < res$abs.error)

fun <- function(x) x^(-1/2)*exp(-x)
(res <- integrate(fun, 0, Inf, rel.tol = 1e-4))
stopifnot(abs(res$value - val) < res$abs.error)
(res <- integrate(fun, 0, Inf, rel.tol = 1e-6))
stopifnot(abs(res$value - val) < res$abs.error)
(res <- integrate(fun, 0, Inf, rel.tol = 1e-8))
stopifnot(abs(res$value - val) < res$abs.error)
## sometimes exceeded reported error in 2.12.0 - 3.0.1


## Unary + should coerce
x <- c(TRUE, FALSE, NA, TRUE)
stopifnot(is.integer(+x))
## +x was logical in R <= 3.0.1


## Attritbutes of value of unary operators
# +x, -x were ts, !x was not in 3.0.2
x <- ts(c(a=TRUE, b=FALSE, c=NA, d=TRUE), frequency = 4, start = 2000)
x; +x; -x; !x
stopifnot(is.ts(!x), !is.ts(+x), !is.ts(-x))
# +x, -x were ts, !x was not in 3.0.2
x <- ts(c(a=1, b=2, c=0, d=4), frequency = 4, start = 2010)
x; +x; -x; !x
stopifnot(!is.ts(!x), is.ts(+x), is.ts(-x))
##


## regression test incorrectly in colorRamp.Rd
bb <- colorRampPalette(2)(4)
stopifnot(bb[1] == bb)
## special case, invalid in R <= 2.15.0:


## Setting NAMED on ... arguments
f <- function(...) { x <- (...); x[1] <- 7; (...) }
stopifnot(f(1+2) == 3)
## was 7 in 3.0.1


## copying attributes from only one arg of a binary operator.
A <- array(c(1), dim = c(1L,1L), dimnames = list("a", 1))
x <- c(a = 1)
B <- A/(pi*x)
stopifnot(is.null(names(B)))
## was wrong in R-devel in Aug 2013
## needed an un-NAMED rhs.


## lgamma(x) for very small negative x
X <- 3e-308; stopifnot(identical(lgamma(-X), lgamma(X)))
## lgamma(-X) was NaN in R <= 3.0.1


## PR#15413
z <- subset(data.frame(one = numeric()), select = one)
stopifnot(nrow(z) == 0L)
## created a row prior to 3.0.2


## https://stat.ethz.ch/pipermail/r-devel/2013-September/067524.html
dbeta(0.9, 9.9e307, 10)
dbeta(0.1, 9,  9.9e307)
dbeta(0.1, 9.9e307, 10)
## first two hung in R <= 3.0.2

## PR#15465
provideDimnames(matrix(nrow = 0, ncol = 1))
provideDimnames(table(character()))
as.data.frame(table(character()))
## all failed in 3.0.2

## PR#15004
n <- 10
s <- 3
l <- 10000
m <- 20
x <- data.frame(x1 = 1:n, x2 = 1:n)
by <- data.frame(V1 = factor(rep(1:3, n %/% s + 1)[1:n], levels = 1:s))
for(i in 1:m) {
    by[[i + 1]] <- factor(rep(l, n), levels = 1:l)
}
agg <- aggregate.data.frame(x, by, mean)
stopifnot(nrow(unique(by)) == nrow(agg))
## rounding caused groups to be falsely merged

## PR#15454
set.seed(357)
z <- matrix(c(runif(50, -1, 1), runif(50, -1e-190, 1e-190)), nrow = 10)
contour(z)
## failed because rounding made crossing tests inconsistent

## Various cases where zero length vectors were not handled properly
## by functions in base and utils, including PR#15499
y <- as.data.frame(list())
format(y)
format(I(integer()))
gl(0, 2)
z <- list(numeric(0), 1)
stopifnot(identical(relist(unlist(z), z), z))
summary(y)
## all failed in 3.0.2

## PR#15518 Parser catching errors in particular circumstance:
(ee <- tryCatch(parse(text = "_"), error= function(e)e))
stopifnot(inherits(ee, "error"))
## unexpected characters caused the parser to segfault in 3.0.2


## nonsense value of nmax
unique(1:3, nmax = 1)
## infinite-looped in 3.0.2, now ignored.


## besselI() (and others), now using sinpi() etc:
stopifnot(all.equal(besselI(2.125,-5+1/1024),
		    0.02679209380095711, tol= 8e-16),
	  all.equal(lgamma(-12+1/1024), -13.053274367453049, tol=8e-16))
## rel.error was 1.5e-13 / 7.5e-14 in R <= 3.0.x
ss <- sinpi(2*(-10:10)-2^-12)
tt <- tanpi(  (-10:10)-2^-12)
stopifnot(ss == ss[1], tt == tt[1], # as internal arithmetic must be exact here
	  all.equal(ss[1], -0.00076699031874270453, tol=8e-16),
	  all.equal(tt[1], -0.00076699054434309260, tol=8e-16))
## (checked via Rmpfr) The above failed during development


## PR#15535 c() "promoted" raw vectors to bad logical values
stopifnot( c(as.raw(11), TRUE) == TRUE )
## as.raw(11) became a logical value coded as 11,
## and did not test equal to TRUE.


## PR#15564
fit <- lm(rnorm(10) ~ I(1:10))
predict(fit, interval = "confidence", scale = 1)
## failed in <= 3.0.2 with object 'w' not found


## PR#15534 deparse() did not produce reparseable complex vectors
assert.reparsable <- function(sexp) {
  deparsed <- paste(deparse(sexp), collapse=" ")
  reparsed <- tryCatch(eval(parse(text=deparsed)[[1]]), error = function(e) NULL)
  if (is.null(reparsed))
    stop(sprintf("Deparsing produced invalid syntax: %s", deparsed))
  if(!identical(reparsed, sexp)) 
    stop(sprintf("Deparsing produced change: value is not %s", reparsed))
}

assert.reparsable(1)
assert.reparsable("string")
assert.reparsable(2+3i)
assert.reparsable(1:10)
assert.reparsable(c(NA, 12, NA, 14))
assert.reparsable(as.complex(NA))
assert.reparsable(complex(real=Inf, i=4))
assert.reparsable(complex(real=Inf, i=Inf))
assert.reparsable(complex(real=Inf, i=-Inf))
assert.reparsable(complex(real=3, i=-Inf))
assert.reparsable(complex(real=3, i=NaN))
assert.reparsable(complex(r=NaN, i=0))
assert.reparsable(complex(real=NA, i=1))
assert.reparsable(complex(real=1, i=NA))
## last 7 all failed

## PR#15621 backticks could not be escaped
stopifnot(deparse(as.name("`"), backtick=TRUE) == "`\\``")
assign("`", TRUE)
`\``
tools::assertError(parse("```"))
## 

proc.time()
