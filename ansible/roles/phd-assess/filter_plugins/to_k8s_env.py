class FilterModule(object):
    '''
    Convert from dict to list of {"name": k, "value": v} dicts.
    '''

    def filters(self):
        return {
            'to_k8s_env': self.to_k8s_env
        }

    def to_k8s_env(self, d):
        return [dict(name=k, value=str(v)) for (k, v) in d.items()]
