/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    watch: {
      core: {
        files: ['src/*.coffee'],
        tasks: ['coffee:core']
      },
      example: {
        files: ['example/coffee/*.coffee'],
        tasks: ['coffee:example']
      }
    },

    coffee: {
      core: {
        src: ['src/angular-parse.coffee'],
        dest: '.',
        options: {bare: false}
      },
      example: {
        src: ['example/coffee/*.coffee'],
        dest: 'example/js'
      },
    },
    testacularServer: {
      unit: {
        configFile: "testacular.conf.js"
      }
    }
  });

  grunt.loadNpmTasks('grunt-testacular');
  grunt.loadNpmTasks('grunt-coffee');

  // Default task.
  grunt.registerTask('default', 'coffee');

  grunt.registerTask('dev', 'server testacularServer watch')


};
