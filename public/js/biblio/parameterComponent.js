Vue.component('parameter-component', {
  template: "#parameter-modal",
  created() {
    this.fetchParameters();
  },
  data: function() {
    return {
      parameters: [],
      name: "",
      type: "",
      value: "",
      force_tag: "",
    }
  },
  methods: {
    fetchParameters() {
      axios.get(baseendpoint+'config', {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'parameter',
          interface_id: this.config.id,
        }
      }).then(response => {
          this.parameters = response.data;
      }).catch(error => {
          console.log(error.response.data);
      });
    },
    addParameter(e) {
      e.preventDefault();
      axios.post(baseendpoint+'config', 
        {
          service: 'biblio',
          table: 'parameter',
          params: {interface_id: this.config.id, name: this.name, type: this.type, value: this.value, force_tag: this.force_tag}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
          this.fetchParameters();
      }).catch(error => {
        console.log(error.response.data);
      });
    }
  },
  props: ['config']
});
Vue.component('parameter-list', {
  template: "#list-parameters",
  data: function() {
    return {
      showUpdate: false
    }
  },
  methods: {
    updateParameter(e) {
      e.preventDefault();
      axios.put(baseendpoint+'config',
      {
        service: 'biblio',
        table: 'parameter',
        id: this.parameter.id,
        params: {interface_id: this.parameter.interface_id, name: this.parameter.name, type: this.parameter.type, value: this.parameter.value, force_tag: this.parameter.force_tag}
      },
      {headers: { Authorization: apitoken }}
      ).then(response => {
        this.updateToggle();
      }).catch(error => {
          console.log(error.response.data);
      });
    },
    deleteParameter(e) {
      e.preventDefault();
      axios.delete(baseendpoint+'config',
      {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'parameter',
          id: this.parameter.id
        }
      }
    ).then(response => {
      this.$parent.fetchParameters();
    });
    },
    updateToggle(){
        this.showUpdate = !this.showUpdate;
    },
  },
  props: ['parameter']
});
