use ExtUtils::MakeMaker;

WriteMakefile
(
 NAME => "Sort::PolySort",
 DISTNAME => "Sort-PolySort",
  VERSION_FROM =>  "lib/Sort/PolySort.pm",
 
 dist         => {
     COMPRESS  => "gzip -9f",
     SUFFIX    => "gz",
 }
);
