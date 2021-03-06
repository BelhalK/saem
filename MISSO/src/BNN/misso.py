# TensorFlow and tf.keras
import tensorflow as tf
K = tf.keras.backend

# Helper libraries
import numpy as np
import matplotlib.pyplot as plt
#%% class MISSO

class MISSO(tf.keras.optimizers.Optimizer):
  """MISSO optimizer.
  Includes support for momentum,
  learning rate decay, and Nesterov momentum.
  Arguments:
      lr: float >= 0. Learning rate.
      momentum: float >= 0. Parameter that accelerates MISSO
          in the relevant direction and dampens oscillations.
      decay: float >= 0. Learning rate decay over each update.
      nesterov: boolean. Whether to apply Nesterov momentum.
  """

  def __init__(self, lr=0.01, momentum=0., decay=0., nesterov=False, **kwargs):
    super(MISSO, self).__init__(**kwargs)
    with K.name_scope(self.__class__.__name__):
      self.iterations = K.variable(0, dtype='int64', name='iterations')
      self.lr = K.variable(lr, name='lr')
      self.momentum = K.variable(momentum, name='momentum')
      self.decay = K.variable(decay, name='decay')
    self.initial_decay = decay
    self.nesterov = nesterov

  def get_updates(self, loss, params):
    grads = self.get_gradients(loss, params)
    self.updates = [state_ops.assign_add(self.iterations, 1)]

    lr = self.lr
    if self.initial_decay > 0:
      lr = lr * (  # pylint: disable=g-no-augmented-assignment
          1. / (1. + self.decay * math_ops.cast(self.iterations,
                                                K.dtype(self.decay))))
    # momentum
    shapes = [K.int_shape(p) for p in params]
    moments = [K.zeros(shape) for shape in shapes]
    self.weights = [self.iterations] + moments
    for p, g, m in zip(params, grads, moments):
      v = self.momentum * m - lr * g  # velocity
      self.updates.append(state_ops.assign(m, v))

      if self.nesterov:
        new_p = p + self.momentum * v - lr * g
      else:
        new_p = p + v

      # Apply constraints.
      if getattr(p, 'constraint', None) is not None:
        new_p = p.constraint(new_p)

      self.updates.append(state_ops.assign(p, new_p))
    return self.updates

  def get_config(self):
    config = {
        'lr': float(K.get_value(self.lr)),
        'momentum': float(K.get_value(self.momentum)),
        'decay': float(K.get_value(self.decay)),
        'nesterov': self.nesterov
    }
    base_config = super(MISSO, self).get_config()
    return dict(list(base_config.items()) + list(config.items()))
