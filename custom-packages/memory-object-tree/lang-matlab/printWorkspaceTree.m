function printWorkspaceTree()
    vars = whos();
    for i = 1:length(vars)
        name = vars(i).name;
        type = vars(i).class;
        var = eval(name);
        if isstruct(var)
            fprintf('* %s: struct\n', name);
            printFields(name, var, 0);
        elseif isobject(var)
            fprintf('* %s: object:%s\n', name, type);
            printFields(name, var, 0);
        else
            fprintf('* %s: %s\n', name, type);
        end
    end
end

function printFields(parentName, obj, depth)
    prefix = repmat('*', 1, depth + 2);  % Start from ** for depth=0 sub-level
    if isstruct(obj)
        fields = fieldnames(obj);
        for j = 1:length(fields)
            fname = fields{j};
            fvalue = obj.(fname);
            ftype = class(fvalue);
            fprintf('%s %s: %s\n', prefix, fname, ftype);
            if isstruct(fvalue) || isobject(fvalue)
                printFields([parentName '.' fname], fvalue, depth + 1);
            end
        end
    elseif isobject(obj)
        props = properties(obj);
        for j = 1:length(props)
            fname = props{j};
            fvalue = obj.(fname);
            ftype = class(fvalue);
            fprintf('%s %s: %s\n', prefix, fname, ftype);
            if isstruct(fvalue) || isobject(fvalue)
                printFields([parentName '.' fname], fvalue, depth + 1);
            end
        end
    end
end
