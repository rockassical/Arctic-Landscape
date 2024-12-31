using System.Collections;
using System.Collections.Generic;
using Unity.XR.CoreUtils.Bindings;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.UI;

public class GetThumbstickValue : MonoBehaviour
{
   public InputActionReference moveAction;

   public Vector2 leftThumbStickInput;



// Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
    leftThumbStickInput = moveAction.action.ReadValue<Vector2>();    
    
    Debug.Log(leftThumbStickInput);
    }
}
