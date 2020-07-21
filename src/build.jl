
function project(xs...)
    joinpath(dirname(dirname(pathof(Comonicon))), xs...)
end

function default_sysimg()
    lib = project("deps", "lib", "libcomonicon.$(Libdl.dlext)")
    if isfile(lib)
        return lib
    else
        return
    end
end

default_exename() = joinpath(Sys.BINDIR, Base.julia_exename())
default_project(mod) = dirname(dirname(pathof(mod)))

function cmd_script(mod; exename=default_exename(), project=default_project(mod), sysimg=default_sysimg(), compile=nothing, optimize=2)
    shebang = "#!$exename --project=$project"

    if sysimg !== nothing
        shebang *= "-J$sysimg"
    end

    if compile in [:yes, :no, :all, :min]
        shebang *= " --compile=$compile"
    end

    shebang *= " -O$optimize"
    return """$shebang
    using $mod; $mod.command_main()
    """
end

function install(mod::Module, name;
        bin=joinpath(first(DEPOT_PATH), "bin"),
        exename=default_exename(),
        project=default_project(mod),
        sysimg=default_sysimg(),
        compile=nothing,
        optimize=2)

    script = cmd_script(mod; exename=exename, project=project, sysimg=sysimg, compile=compile, optimize=optimize)
    file = joinpath(bin, name)

    if !ispath(bin)
        @info "cannot find Julia bin folder creating .julia/bin"
        mkpath(bin)
    end

    @info "generating $file"
    open(file, "w+") do f
        println(f, script)
    end

    chmod(file, 0o777)
    return
end

function Base.write(io::IO, x::EntryCommand; exec=false)
    println(io, "#= generated by Comonicon =#")
    println(io, rm_lineinfo(codegen(x)))
    if exec
        println(io, "command_main()")
    end
end

function build()
    if !ispath(project("deps", "lib"))
        mkpath(project("deps", "lib"))
    end

    create_sysimage([:Comonicon, :Test];
        sysimage_path=project("deps", "lib", "libcomonicon.$(Libdl.dlext)"),
        project=project(), precompile_execution_file=project("test", "runtests.jl")
    )        
end