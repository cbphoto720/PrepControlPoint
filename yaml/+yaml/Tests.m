classdef Tests < matlab.unittest.TestCase

    properties (TestParameter)

        % Parameters for testing 'yaml.load'.
        LOAD_TEST = nest({
            % YAML                  Expected result

            % Test special cases.
            "test # comment",       "test"
            "True",                 true
            "true",                 true
            "False",                false
            "false",                false
            ".nan",                 NaN
            ".inf",                 inf
            "-.inf",                -inf
            "null",                 []
            "",                     []
            "~",                    []
            "{}",                   struct()

            % Test mixed types.
            "[1, 2, True, test]",   {1; 2; true; "test"}
            sprintf("- - [1.0, a]\n  - null\n- {f1: 1.0}\n- [1.0, 2.0, true]"), {{{1; "a"}; []}; str("f1", 1); {1; 2; true}} 

            % Test maps.
            sprintf("a: test\nb: 123\nc:\n  d: test2\n  e: False"), str("a", "test", "b", 123, "c", str("d", "test2", "e", false))
            "[{a: 1, b: 2}, {a: 2, b: 3}]",                         {str("a", 1, "b", 2); str("a", 2, "b", 3)}                
            "[[{a: 1}, {a: 2}], [{a: 3}, {a: 4}]]",                 {{str("a", 1); str("a", 2)}; {str("a", 3); str("a", 4)}}
            sprintf("12!: 1\n12$: 2"),                              str("x12_", 1, "x12__1", 2)
            
            % Test datetimes.
            "2019-09-07T15:50:00",  datetime(2019, 9, 7, 15, 50, 0, "TimeZone", "UTC")
            "2019-09-07 15:50:00",  datetime(2019, 9, 7, 15, 50, 0, "TimeZone", "UTC")
            "2019-09-07",           datetime(2019, 9, 7, "TimeZone", "UTC")
            "2019 09 07 15:50:00",  "2019 09 07 15:50:00"
        });

        % Parameters for testing 'yaml.load' with 'ConvertToArray' option.
        CONVERT_TO_ARRAY_TEST = nest({
            % YAML              Expected result
            "[]",               zeros(1, 0)
            "[[1, 2], []]",     {[1; 2]; zeros(1, 0)}
            "[[1, 2], [3]]",    {[1; 2]; 3}
            "[1, true]",        {1; true}
            "[[a, b], [c, d]]", ["a", "b"; "c", "d"]
            "[null, 1]",        {[]; 1}
            "[null, null]",     {[]; []}

            % 1D struct array
            "[{a: 1, b: 2}, {a: 2, b: 3}]", str("a", {1; 2}, "b", {2; 3})
            "[{a: 1, b: 2}, {a: 2, c: 3}]", {str("a", 1, "b", 2); str("a", 2, "c", 3)}

            % 2D struct array
            "[[{a: 1}, {a: 2}], [{a: 3}, {a: 4}]]", str("a", {1, 2; 3, 4})
            "[[{a: 1}, {a: 2}], [{a: 3}, {b: 4}]]", {str("a", {1; 2}); {str("a", 3); str("b", 4)}}
            "[[{a: 1}, {a: 2}], [{b: 3}, {b: 4}]]", {str("a", {1; 2}); str("b", {3; 4})}
            "[[{a: 1}, {b: 2}], [{c: 3}, {d: 4}]]", {str("a", 1), str("b", 2); str("c", 3), str("d", 4)}
        });

        % Parameters for testing 'yaml.dump'.
        DUMP_TEST = nest({
            % Data          Expected YAML
            1.23,           "1.23"
            pi,             "3.141592653589793"
            "test",         "test"
            'test',         "test"
            't',            "t"
            
            true,           "true"
            struct("a", "test", "b", 123), "{a: test, b: 123.0}"
            {1, "test"},    "[1.0, test]"
            {1; "test"},    "[1.0, test]"
            {1, {2, 3}},    sprintf("- 1.0\n- [2.0, 3.0]")
            nan,            ".NaN"
            inf,            ".inf"
            -inf,           "-.inf"
            [],             "null"
            {},             "null"
            [1, 2],         "[1.0, 2.0]"
            ["a", "b"],     "[a, b]"
            [true, false],  "[true, false]"
            zeros(1, 0),    "[]"
            zeros(0, 1),    "[]"
            cell(0, 1),    "[]"
            cell(1, 0),    "[]"
            num2cell(int32(ones(2, 2, 2))), sprintf("- - [1, 1]\n  - [1, 1]\n- - [1, 1]\n  - [1, 1]")
            int32(ones(2, 1, 2)),           sprintf("- - [1, 1]\n- - [1, 1]")
            {{{1, "a"}, []}, str("f1", 1), {1, 2, true}}, sprintf("- - [1.0, a]\n  - null\n- {f1: 1.0}\n- [1.0, 2.0, true]")
        })

        % Parameters for testing consistency of dumping and reloading.
        DUMP_RELOAD_TEST_DATA_GENERATOR = {
            @() buildRandomFloat
            @() logical(randi(2)-1)
            @() randi(2^8, "uint8")
            @() randi(2^8, "uint16")
            @() randi(2^8, "uint32")
            @() uint64(randi(2^8))
            @() randi(2^8, "int8")
            @() randi(2^8, "int16")
            @() randi(2^8, "int32")
            @() uint64(randi(2^8))
            @() buildRandomString()
        }
        DUMP_RELOAD_TEST_NUM_DIM = {0, 1, 2, 3, 4};
        DUMP_RELOAD_TEST_INDEX = num2cell(1:3);

        % Parameters for testing errors of 'yaml.dump'.
        INVALID_DUMP_DATA = nest({
            % Data                      Expected error
            num2cell(ones(2, 2, 2, 2)), "yaml:dump:HigherDimensionsNotSupported"
            datetime(2022, 2, 13),      "yaml:dump:TypeNotSupported"
        });

        % Parameters of testing dumping of integer types.
        INTEGER_TYPE = {"uint8", "uint16", "uint32", "uint64", "int8", "int16", "int32", "int64"}
        INTEGER_LIMIT_FUNCTION = {@intmin, @intmax}

    end

    methods (TestClassSetup)
        function initRng(testCase)
            rng(0)
        end
    end

    methods (Test)

        function load(testCase, LOAD_TEST)
            [s, expected] = LOAD_TEST{:};
            actual = yaml.load(s);
            testCase.verifyEqual(actual, expected);
        end

        function load_convertToArray(testCase, CONVERT_TO_ARRAY_TEST)
            [s, expected] = CONVERT_TO_ARRAY_TEST{:};
            actual = yaml.load(s, "ConvertToArray", true);
            testCase.verifyEqual(actual, expected);
        end

        function dump(testCase, DUMP_TEST)
            [data, expected] = DUMP_TEST{:};
            expected = expected + newline;
            actual = yaml.dump(data);
            testCase.verifyEqual(actual, expected);
        end

        function dump_integer(testCase, INTEGER_TYPE, INTEGER_LIMIT_FUNCTION)
            data = INTEGER_LIMIT_FUNCTION(INTEGER_TYPE);
            expected = string(data) + newline;
            actual = yaml.dump(data);
            testCase.verifyEqual(actual, expected);

            dataArray = data * ones(2, 2, 2, INTEGER_TYPE);
            expected = compose("- - [%s, %s]\n  - [%s, %s]\n- - [%s, %s]\n  - [%s, %s]\n", repelem(string(data), 8));
            actual = yaml.dump(dataArray);
            testCase.verifyEqual(actual, expected);
        end

        function dumpReloadUniformData(testCase, DUMP_RELOAD_TEST_DATA_GENERATOR, DUMP_RELOAD_TEST_NUM_DIM, DUMP_RELOAD_TEST_INDEX)
            % Assert that dumping and reloading does not change the data. 
            % Exception: Integers are loaded as doubles.

            % Size of all array dimensions.
            DIM_SIZE = 2; 

            % Create N-D array of random values.
            nDims = DUMP_RELOAD_TEST_NUM_DIM;
            numElements = DIM_SIZE^DUMP_RELOAD_TEST_NUM_DIM;
            original = arrayfun(@(x) DUMP_RELOAD_TEST_DATA_GENERATOR(), zeros(numElements, 1));
            if nDims > 0
                if nDims == 1
                    size_ = [DIM_SIZE, 1];
                else
                    size_ = DIM_SIZE * ones(1, DUMP_RELOAD_TEST_NUM_DIM);
                end
                original = reshape(original, size_);
            end

            % Dump, reload and compare.
            yamlValue = yaml.dump(original);
            loaded = yaml.load(yamlValue, ConvertToArray=true);
            if isinteger(original)
                original = double(original);
            end
            testCase.verifyEqual(loaded, original)
        end

        function dump_unsupportedTypes(testCase, INVALID_DUMP_DATA)
            [data, errorId] = INVALID_DUMP_DATA{:};
            func = @() yaml.dump(data);
            testCase.verifyError(func, errorId);
        end

        function dump_style(testCase)
            data.a = 1;
            data.b = {3, {4}};

            tests = {
                "block", sprintf("a: 1.0\nb:\n- 3.0\n- - 4.0\n")
                "flow", sprintf("{a: 1.0, b: [3.0, [4.0]]}\n")
                "auto", sprintf("a: 1.0\nb:\n- 3.0\n- [4.0]\n")
                };

            for iTest = 1:size(tests, 1)
                [style, expected] = tests{iTest, :};
                actual = yaml.dump(data, style);
                testCase.verifyEqual(actual, expected);
            end

        end

        function dumpFile(testCase)
            data = struct("a", 1.23, "b", "test");
            expected = "{a: 1.23, b: test}";
            if ispc
                expected = expected + sprintf("\r\n");
            else
                expected = expected + sprintf("\n");
            end

            testPath = tempname;

            yaml.dumpFile(testPath, data)
            fid = fopen(testPath);
            actual = string(fscanf(fid, "%c"));
            fclose(fid);

            testCase.verifyEqual(actual, expected);

            delete(testPath)
        end

        function loadFile(testCase)
            data = struct("a", 1.23, "b", "test");

            testPath = tempname;
            yaml.dumpFile(testPath, data)
            actual = yaml.loadFile(testPath);

            testCase.verifyEqual(actual, data);
            delete(testPath)
        end

        function loadFile_convertToArray(testCase)
            data = {1, 2};
            expected = [1; 2];

            testPath = tempname;
            yaml.dumpFile(testPath, data)
            actual = yaml.loadFile(testPath, "ConvertToArray", true);

            testCase.verifyEqual(actual, expected);
            delete(testPath)
        end

    end

end

function nestedCell = nest(cell2d)
    n = size(cell2d, 1);
    nestedCell = cell(1, n);
    for i = 1:n
        nestedCell{i} = cell2d(i, :);
    end
end

function y = str(varargin)
    y = struct(varargin{:});
end

function result = buildRandomString()
    result = string(char(randi(94, 1, 10) + 32));
end

function result = buildRandomFloat()
    result = rand(1)^(randi(20, 1) - 10);
end
