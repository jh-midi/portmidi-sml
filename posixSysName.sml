 
fun getSysName () = let
    val uname =  Posix.ProcEnv.uname()
    val sysname = List.find (fn (key,x) =>  key = "sysname") uname
in
    if sysname = NONE then "?"
    else #2 (valOf sysname)
end


