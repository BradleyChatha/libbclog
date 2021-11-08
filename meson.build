project('libbclog', 'd')

libbcfmt_dep = subproject('libbcfmt').get_variable('libbcfmt_dep')

src = [
    'source/libbc/log/core.d',
    'source/libbc/log/sinks.d',
    'source/libbc/log/package.d'
]

include = include_directories('source/')

libbclog = static_library('bclog', src, include_directories: include, dependencies: libbcfmt_dep, d_args: '-betterC')
libbclog_dep = declare_dependency(sources: src, include_directories: include, dependencies: libbcfmt_dep)

libbclog_bench = executable('bench', src, 'benchmark/main.d', dependencies: libbclog_dep)