#!/usr/bin/env python3

import sys, re, os

def patch_llvmir(filename):
    # we need to patch
    result = []
    if os.path.isfile(filename):
        with open(filename) as f:
            for line in f:
                # patch calling convention for functions
                m = re.match('^define(?!.*amdgpu_gfx.*) (?:linkonce_odr) (?:protected) (.*) @(.*)\n$', line)
                if m is not None:
                    ty, rest = m.groups()
                    print("Patching function ID {0} in {1}".format(rest, filename))
                    result.append('define amdgpu_gfx {0} @{1}\n'.format(ty, rest))
                    continue

                # patch calling convention for function calls
                m = re.match('(?!.*amdgpu_gfx.*)(.*) call (?!.*@llvm.*)(.*)\n$', line)
                #  %7 = tail call double @llvm.fma.f64(double %6, double 0x3FA059859FEA6A70, double 0xBF90A5A378A05EAF)
                if m is not None:
                    pre, post = m.groups()
                    print("Patching function call {0} amdgpu_gfx {1}".format(pre, post))
                    result.append('{0} call amdgpu_gfx {1}\n'.format(pre, post))
                    continue

                result.append(line)

        # we have the patched thing, write it
        with open(filename, "w") as f:
            for line in result:
                f.write(line)
    return

patch_llvmir("ocml.ll")