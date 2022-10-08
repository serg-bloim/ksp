def ensure_list(lst):
    if isinstance(lst, list):
        return lst
    else:
        return [lst]