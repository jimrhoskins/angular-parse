module.exports = (grunt) ->
  # Project configuration.
  grunt.initConfig
    relativePath: ''

    coffee:
      main:
        files: [
          expand: true
          cwd: 'src/'
          src: ['**/*.coffee']
          dest: '.'
          ext: '.js'
        ,
          expand: true
          cwd: 'example/coffee'
          src: ['**/*.coffee']
          dest: 'example/js'
          ext: '.js'
        ]

    karma:
      options:
        configFile: 'karma.conf.js'
      unit:
        background: true
      single:
        singleRun: true

    connect:
      main:
        options:
          port: 9001
          base: 'build/'

    watch:
      main:
        options:
          livereload: false
        files: ['src/**/*.coffee', 'test/**/*.coffee']
        tasks: ['coffee', 'karma:unit:run']

  grunt.loadNpmTasks name for name of grunt.file.readJSON('package.json').devDependencies when name[0..5] is 'grunt-'

  grunt.registerTask 'default', ['coffee', 'karma:unit', 'watch:main']
  grunt.registerTask 'test', ['karma:single']
  grunt.registerTask "parse-deploy", ->
    done = @async()
    grunt.utils.spawn
      cmd: "parse"
      args: ["deploy"]
      opts:
        cwd: "./example/parse"
    , -> done()