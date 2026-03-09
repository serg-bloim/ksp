function map{
    PARAMETER func.
    PARAMETER lst.
    local res is LIST().
    for i in lst{
        res:ADD(func(i)).
    }
    RETURN res.
}