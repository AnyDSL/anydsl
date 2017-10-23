
set print object on

define tdump
  call $arg0->dump()
end
document tdump
  Dump a Thorin/Impala-dumpable object.
end

define ttdump
  call ($arg0)->type()->dump()
end
document tdump
  Dump a Thorin/Impala-dumpable object.
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
