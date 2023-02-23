new Vue({
    el: '#interfaceApp',
    created() {
        this.fetchData();	
    },
    data: {
        errors: [],
        configs: [],
        parameters: [],
        interface: "",
        name: "",
        type: "",
        method: "",
        format: "",
        endpoint_url: "",
        auth_url: ""
    },
    methods: {
        fetchData() {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'interface'
          }
        }).then(response => {
            this.configs = response.data;
            });
        },
        addConfig() {
        axios.post(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            params: {interface: this.interface, name: this.name, type: this.type, method: this.method, format: this.format, endpoint_url: this.endpoint_url}
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
            this.fetchData();
        }).catch(error => {
            this.errors.push('Duplicate entry!');
        });
        },
        updateConfig(config) {
          axios.put(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            id: config.id,
            params: {interface: config.interface, name: config.name, type: config.type, method: config.method, format: config.format, endpoint_url: config.endpoint_url}
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
            
            });
        },
        deleteConfig(config) {
          axios.delete(baseendpoint+'config',
          {
            headers: { Authorization: apitoken },
            params: {
              service: 'biblio',
              table: 'interface',
              id: config.id
            }
          }
        ).then(response => {
            this.fetchData();
            });
        },
        checkForm(e) {
            var url_validate = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
          if (this.name && this.interface && this.type && this.endpoint_url && url_validate.test(this.endpoint_url)) {
            this.addConfig();
          } 
          this.errors = [];

          if (!this.name) {
            this.errors.push('Name required.');
          }
          if (!this.interface) {
            this.errors.push('Interface required.');
          }
          if (!this.type) {
            this.errors.push('Type required.');
          }
          if (!this.endpoint_url) {
            this.errors.push('Url required.');
          }
          if (!url_validate.test(this.endpoint_url)) {
            this.errors.push('Incorrect url.');
          }
          e.preventDefault();
        }
    }
});
Vue.component('config-list', {
  template: "#list-items",
  data: function() {
    return {
      showUpdate: false,
      host: this.config.host
    }
  },
  methods: {
    updateConfig(config){
        this.showUpdate = false;
        this.$parent.updateConfig(config);
    },
    deleteConfig(config){
        this.showUpdate = false;
        this.$parent.deleteConfig(config);
    },
    updateToggle(){
        this.showUpdate = !this.showUpdate;
    },
    updateHost() {
      this.host = !this.host;
      axios.put(baseendpoint+'config',
        {
          service: 'biblio',
          table: 'interface',
          id: this.config.id,
          params: {host: this.host}
        },
        {headers: { Authorization: apitoken }}
        ).then(response => {
          this.$parent.fetchData();
        }).catch(error => {
          console.log(error.response.data);
        });
    }
  },
  props: ['config']
});
