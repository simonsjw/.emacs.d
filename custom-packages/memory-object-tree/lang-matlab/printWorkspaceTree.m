function printWorkspaceTree()
    % printWorkspaceTree - Prints a tree representation of the current MATLAB workspace.
    %
    % Description:
    %   This function retrieves all variables in the base workspace using 'evalin' to
    %   execute 'whos' in the 'base' context, as 'whos()' alone inside a function only
    %   captures local variables. It then prints them in a hierarchical tree format to
    %   stdout using fprintf. Top-level variables are prefixed with '*', and nested
    %   fields/properties (for structs or objects) are indented with additional '*' for
    %   each depth level. This output is designed to be captured and parsed by external
    %   tools, such as Emacs Speedbar.
    %
    %   To include memory usage, the function now appends the 'bytes' field from 'whos'
    %   for top-level variables and calculates approximate memory for nested fields where
    %   possible (using 'whos' on temporary variables). No return value is needed, as
    %   output is directed to stdout via fprintf.
    %
    % Example:
    %   >> a = 5;               % Simple variable
    %   >> s = struct('f1', 1); % Struct with field
    %   >> printWorkspaceTree()
    %   * a: double (8 bytes)
    %   * s: struct (152 bytes)
    %   ** f1: double (8 bytes)
    %
    % See also: whos, evalin, fprintf, isstruct, isobject, fieldnames, properties

    % Get all variables in the base workspace
    vars = evalin('base', 'whos()');

    function printFields(parentName, obj, depth)
        % printFields - Recursively prints fields/properties of a struct or object.
        %
        % Inputs:
        %   parentName - String: Full path name of the parent (e.g., 's.f1')
        %   obj        - Struct or Object: The item to inspect
        %   depth      - Integer: Current recursion depth (starts at 1 for first nest)
        %
        % Description:
        %   Prints nested fields/properties with increasing '*' prefixes based on depth.
        %   Recurses if a field/property is itself a struct or object. Memory usage is
        %   approximated using 'whos' on a temporary copy of the field/property. Output
        %   goes to stdout via fprintf.
        %
        %   This is a helper function for printWorkspaceTree and not intended for direct use.

        % Create prefix string with (depth + 1) '*' (since top-level is 1 '*')
        prefix = repmat('*', 1, depth + 1);

        if isstruct(obj)
            % Get field names for struct
            fields = fieldnames(obj);
            for j = 1:length(fields)
                fname = fields{j};          % Field name
                fvalue = obj.(fname);       % Field value
                ftype = class(fvalue);      % Field type

                % Approximate memory usage for this field
                tempVar = fvalue;           % Temporary copy to measure
                tempInfo = whos('tempVar'); % Get size info
                fbytes = tempInfo.bytes;    % Extract bytes
                clear tempVar;              % Clean up temporary

                % Print field with prefix and memory
                fprintf('%s %s: %s (%d bytes)\n', prefix, fname, ftype, fbytes);

                % Recurse if nested struct or object
                if isstruct(fvalue) || isobject(fvalue)
                    printFields([parentName '.' fname], fvalue, depth + 1);
                end
            end
        elseif isobject(obj)
            % Get properties for object
            props = properties(obj);
            for j = 1:length(props)
                fname = props{j};           % Property name
                fvalue = obj.(fname);       % Property value
                ftype = class(fvalue);      % Property type

                % Approximate memory usage for this property
                tempVar = fvalue;           % Temporary copy to measure
                tempInfo = whos('tempVar'); % Get size info
                fbytes = tempInfo.bytes;    % Extract bytes
                clear tempVar;              % Clean up temporary

                % Print property with prefix and memory
                fprintf('%s %s: %s (%d bytes)\n', prefix, fname, ftype, fbytes);

                % Recurse if nested struct or object
                if isstruct(fvalue) || isobject(fvalue)
                    printFields([parentName '.' fname], fvalue, depth + 1);
                end
            end
        end
    end

    % Loop through each variable
    for i = 1:length(vars)
        name = vars(i).name;   % Variable name
        type = vars(i).class;  % Variable class/type
        bytes = vars(i).bytes; % Memory usage in bytes

        % Print top-level variable with '*' prefix and memory
        fprintf('* %s: %s (%d bytes)\n', name, type, bytes);

        % If it's a struct or object, recursively print nested fields/properties
        if strcmp(type, 'struct') || isobject(evalin('base', name))
            obj = evalin('base', name);  % Fetch from base workspace
            printFields(name, obj, 1);   % Start recursion at depth 1
        end
    end
end
