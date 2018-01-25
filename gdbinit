
set print object on

define td
  call $arg0->dump()
end
document td
  Dump a Thorin/Impala-dumpable object.
end

define ttd
  call ($arg0)->type()->dump()
end
document ttd
  Dump a Thorin/Impala-dumpable object's type.
end

define tos
  call ($arg0)->to_string()
end
document tos
  Call to_string on an object.
end

define ttos
  call ($arg0)->type()->to_string()
end
document ttos
  Call to_string on the type() of an object.
end

define wrthorin
  call ($arg0).thorin()
  call ($arg0).write_thorin($arg1)
end
document wrthorin
  Write thorin representation to the file given as argument.
end
